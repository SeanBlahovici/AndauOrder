import Foundation
import Observation
import SwiftData

@Observable
final class OrderFormViewModel {
    var formData: OrderFormData
    var currentTab: OrderFormTab = .customerInfo
    var hasUnsavedChanges: Bool = false

    private let orderRecord: OrderRecord?
    private let modelContext: ModelContext

    /// Create a new order
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.formData = OrderFormData()
        self.orderRecord = nil
    }

    /// Edit an existing order
    init(orderRecord: OrderRecord, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.orderRecord = orderRecord
        self.formData = orderRecord.orderData ?? OrderFormData()
    }

    var isNewOrder: Bool {
        orderRecord == nil
    }

    var syncStatus: SyncStatus {
        orderRecord?.syncStatus ?? .draft
    }

    // MARK: - Auto-Pricing

    /// Recalculate pricing from the price catalog based on current product selections
    func recalculatePricing() {
        let catalog = fetchCatalog()
        guard !catalog.isEmpty else { return }

        let promotion = formData.pricing.lessPromotion
        let taxRate = formData.pricing.taxRate

        formData.pricing = PriceCatalogLookup.buildPricing(from: formData, catalog: catalog)

        // Preserve user-entered values
        formData.pricing.lessPromotion = promotion
        formData.pricing.taxRate = taxRate
    }

    private func fetchCatalog() -> [PriceCatalogEntry] {
        let descriptor = FetchDescriptor<PriceCatalogEntry>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Persistence

    func save() {
        if let orderRecord {
            orderRecord.orderData = formData
        } else {
            let record = OrderRecord(orderData: formData)
            modelContext.insert(record)
        }

        do {
            try modelContext.save()
            hasUnsavedChanges = false
        } catch {
            print("Failed to save order: \(error)")
        }
    }

    /// Enqueues sync steps for this order. Call `syncCoordinator.syncNow()` from the view afterwards.
    func markForSync(syncCoordinator: SyncCoordinator) {
        save()
        if let orderRecord {
            orderRecord.syncStatus = .pendingSync
            do {
                try syncCoordinator.syncEngine.enqueueSync(for: orderRecord, modelContext: modelContext)
                try modelContext.save()
            } catch {
                print("Failed to enqueue sync: \(error)")
            }
        }
    }

    // MARK: - Navigation

    func nextTab() {
        if let next = currentTab.next {
            currentTab = next
        }
    }

    func previousTab() {
        if let prev = currentTab.previous {
            currentTab = prev
        }
    }

    var canGoNext: Bool {
        currentTab.next != nil
    }

    var canGoPrevious: Bool {
        currentTab.previous != nil
    }

    // MARK: - Validation

    var isCustomerInfoComplete: Bool {
        !formData.customer.firstName.isEmpty
            && !formData.customer.lastName.isEmpty
            && !formData.customer.email.isEmpty
    }

    var isProductSelected: Bool {
        formData.loupeSelection.isSelected
    }

    var isReadyToSubmit: Bool {
        isCustomerInfoComplete && isProductSelected
    }
}

// MARK: - Tab Definition

enum OrderFormTab: Int, CaseIterable, Identifiable, Sendable {
    case customerInfo = 0
    case products = 1
    case customization = 2
    case pricing = 3
    case reviewChecklist = 4
    case reviewSubmit = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .customerInfo: "Customer"
        case .products: "Products"
        case .customization: "Customization"
        case .pricing: "Pricing"
        case .reviewChecklist: "Review"
        case .reviewSubmit: "Submit"
        }
    }

    var icon: String {
        switch self {
        case .customerInfo: "person"
        case .products: "eyeglasses"
        case .customization: "wrench.and.screwdriver"
        case .pricing: "dollarsign.circle"
        case .reviewChecklist: "checklist"
        case .reviewSubmit: "paperplane"
        }
    }

    var next: OrderFormTab? {
        OrderFormTab(rawValue: rawValue + 1)
    }

    var previous: OrderFormTab? {
        OrderFormTab(rawValue: rawValue - 1)
    }
}
