import Foundation
import SwiftData
import Observation

@Observable
final class SyncEngine: @unchecked Sendable {
    private let authService: ZohoAuthService
    private let crmService: ZohoCRMServiceProtocol
    private let booksService: ZohoBooksServiceProtocol

    private static let maxAutoRetries = 5

    init() {
        let authService = ZohoAuthService()
        self.authService = authService
        let httpClient = HTTPClient(authService: authService)
        self.crmService = ZohoCRMService(httpClient: httpClient)
        self.booksService = ZohoBooksService(httpClient: httpClient)
    }

    // MARK: - Enqueue

    func enqueueSync(for orderRecord: OrderRecord, modelContext: ModelContext) throws {
        let steps: [(Int, SyncStepType)] = [
            (0, .createLead),
            (1, .transitionLeadToTMReachedOut),
            (2, .transitionLeadToCustomerEngaged),
            (3, .fetchCreatedRecords),
            (4, .transitionDealToQualified),
            (5, .updateDealDetails),
            (6, .createBooksCustomer),
            (7, .createEstimate),
        ]

        // Remove any existing queue entries for this order before re-enqueuing
        let orderID = orderRecord.id
        let existing = try modelContext.fetch(
            FetchDescriptor<SyncQueueEntry>(
                predicate: #Predicate<SyncQueueEntry> { $0.orderID == orderID }
            )
        )
        for entry in existing {
            modelContext.delete(entry)
        }

        for (order, stepType) in steps {
            let entry = SyncQueueEntry(orderID: orderRecord.id, stepType: stepType, stepOrder: order)
            modelContext.insert(entry)
        }

        orderRecord.syncStatus = .syncing
    }

    // MARK: - Process Queue

    @MainActor
    func processQueue(modelContext: ModelContext) async {
        let pendingSyncRaw = SyncStatus.pendingSync.rawValue
        let partiallySyncedRaw = SyncStatus.partiallySynced.rawValue
        let failedRaw = SyncStatus.failed.rawValue
        let syncingRaw = SyncStatus.syncing.rawValue

        let orders: [OrderRecord]
        do {
            orders = try modelContext.fetch(
                FetchDescriptor<OrderRecord>(
                    predicate: #Predicate<OrderRecord> {
                        $0.syncStatusRaw == pendingSyncRaw
                            || $0.syncStatusRaw == partiallySyncedRaw
                            || $0.syncStatusRaw == failedRaw
                            || $0.syncStatusRaw == syncingRaw
                    }
                )
            )
        } catch {
            print("Failed to fetch orders for sync: \(error)")
            return
        }

        for order in orders {
            await processOrder(order, modelContext: modelContext)
        }
    }

    // MARK: - Retry Failed

    @MainActor
    func retryFailed(orderID: UUID, modelContext: ModelContext) async {
        let failedRaw = SyncStepStatus.failed.rawValue

        do {
            let entries = try modelContext.fetch(
                FetchDescriptor<SyncQueueEntry>(
                    predicate: #Predicate<SyncQueueEntry> {
                        $0.orderID == orderID && $0.statusRaw == failedRaw
                    }
                )
            )
            for entry in entries {
                entry.status = .pending
                entry.attemptCount = 0
                entry.lastError = nil
            }
            try modelContext.save()
        } catch {
            print("Failed to reset entries for retry: \(error)")
            return
        }

        await processQueue(modelContext: modelContext)
    }

    // MARK: - Private

    @MainActor
    private func processOrder(_ order: OrderRecord, modelContext: ModelContext) async {
        let orderID = order.id
        let entries: [SyncQueueEntry]
        do {
            entries = try modelContext.fetch(
                FetchDescriptor<SyncQueueEntry>(
                    predicate: #Predicate<SyncQueueEntry> { $0.orderID == orderID },
                    sortBy: [SortDescriptor(\.stepOrder)]
                )
            )
        } catch {
            print("Failed to fetch sync entries: \(error)")
            return
        }

        guard let formData = order.orderData else {
            order.syncStatus = .failed
            order.syncErrorMessage = "Order data is missing"
            try? modelContext.save()
            return
        }

        var hadFailure = false

        for entry in entries {
            // Skip completed and skipped entries
            if entry.status == .completed || entry.status == .skipped {
                continue
            }

            // Only process pending or failed entries
            guard entry.status == .pending || entry.status == .failed else {
                continue
            }

            // Max auto-retry check
            if entry.attemptCount >= Self.maxAutoRetries {
                hadFailure = true
                break
            }

            // Mark in progress
            entry.status = .inProgress
            try? modelContext.save()

            do {
                try await executeStep(entry, order: order, formData: formData)
                entry.status = .completed
                try? modelContext.save()
            } catch {
                entry.status = .failed
                entry.attemptCount += 1
                entry.lastError = error.localizedDescription
                order.lastSyncAttempt = Date()
                try? modelContext.save()
                hadFailure = true
                break // Don't skip ahead on failure
            }
        }

        // Update order sync status
        updateOrderSyncStatus(order, entries: entries)
        try? modelContext.save()
    }

    private func updateOrderSyncStatus(_ order: OrderRecord, entries: [SyncQueueEntry]) {
        let allCompleted = entries.allSatisfy { $0.status == .completed || $0.status == .skipped }
        let anyFailed = entries.contains { $0.status == .failed }
        let anyCompleted = entries.contains { $0.status == .completed }

        if allCompleted {
            order.syncStatus = .synced
            order.syncErrorMessage = nil
        } else if anyFailed {
            order.syncStatus = .failed
            order.syncErrorMessage = entries.first(where: { $0.status == .failed })?.lastError
        } else if anyCompleted {
            order.syncStatus = .partiallySynced
        }
        // If nothing completed yet and nothing failed, leave as syncing
    }

    @MainActor
    private func executeStep(_ entry: SyncQueueEntry, order: OrderRecord, formData: OrderFormData) async throws {
        switch entry.stepType {
        case .createLead:
            // Idempotency: skip if lead already created
            if let existingID = order.zohoLeadID {
                entry.zohoRecordID = existingID
                return
            }
            let leadID = try await crmService.createLead(from: formData)
            order.zohoLeadID = leadID
            entry.zohoRecordID = leadID

        case .transitionLeadToTMReachedOut:
            guard let leadID = order.zohoLeadID else { throw APIError.invalidResponse }
            let transitions = try await crmService.getBlueprint(module: "Leads", recordID: leadID)
            guard let transition = transitions.first(where: { $0.name.contains("TM Reached Out") || $0.name.contains("Reached") }) else {
                throw APIError.zohoError(code: "NO_TRANSITION", message: "TM Reached Out transition not found")
            }
            try await crmService.executeTransition(module: "Leads", recordID: leadID, transitionID: transition.id, data: nil)

        case .transitionLeadToCustomerEngaged:
            guard let leadID = order.zohoLeadID else { throw APIError.invalidResponse }
            let transitions = try await crmService.getBlueprint(module: "Leads", recordID: leadID)
            guard let transition = transitions.first(where: { $0.name.contains("Customer Engaged") || $0.name.contains("Engaged") }) else {
                throw APIError.zohoError(code: "NO_TRANSITION", message: "Customer Engaged transition not found")
            }
            try await crmService.executeTransition(module: "Leads", recordID: leadID, transitionID: transition.id, data: nil)

        case .fetchCreatedRecords:
            guard let leadID = order.zohoLeadID else { throw APIError.invalidResponse }
            let result = try await crmService.convertLead(leadID: leadID, order: formData)
            order.zohoContactID = result.contactID
            order.zohoAccountID = result.accountID
            order.zohoDealID = result.dealID

        case .transitionDealToQualified:
            guard let dealID = order.zohoDealID else { throw APIError.invalidResponse }
            let transitions = try await crmService.getBlueprint(module: "Deals", recordID: dealID)
            guard let transition = transitions.first(where: { $0.name.contains("Qualified") }) else {
                throw APIError.zohoError(code: "NO_TRANSITION", message: "Qualified transition not found")
            }
            try await crmService.executeTransition(module: "Deals", recordID: dealID, transitionID: transition.id, data: nil)

        case .updateDealDetails:
            guard let dealID = order.zohoDealID else { throw APIError.invalidResponse }
            try await crmService.updateDeal(dealID: dealID, stage: "Qualified", closingDate: formData.date, amount: formData.pricing.total)

        case .createBooksCustomer:
            // Idempotency: skip if books customer already set
            if let existingID = order.zohoBooksCustID {
                entry.zohoRecordID = existingID
                return
            }
            if let existing = try await booksService.searchCustomer(email: formData.customer.email) {
                order.zohoBooksCustID = existing.contact_id
                entry.zohoRecordID = existing.contact_id
            } else {
                let custID = try await booksService.createCustomer(from: formData)
                order.zohoBooksCustID = custID
                entry.zohoRecordID = custID
            }

        case .createEstimate:
            guard let custID = order.zohoBooksCustID else { throw APIError.invalidResponse }
            let estID = try await booksService.createEstimate(customerID: custID, order: formData)
            order.zohoEstimateID = estID
            entry.zohoRecordID = estID
        }
    }
}
