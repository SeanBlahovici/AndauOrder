import Foundation
import SwiftData

@Model
final class OrderRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var orderDataJSON: Data
    var syncStatusRaw: String
    var zohoLeadID: String?
    var zohoContactID: String?
    var zohoAccountID: String?
    var zohoDealID: String?
    var zohoEstimateID: String?
    var zohoBooksCustID: String?
    var lastSyncAttempt: Date?
    var syncErrorMessage: String?

    init(orderData: OrderFormData) {
        self.id = orderData.id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.orderDataJSON = (try? JSONEncoder().encode(orderData)) ?? Data()
        self.syncStatusRaw = SyncStatus.draft.rawValue
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .draft }
        set { syncStatusRaw = newValue.rawValue }
    }

    var orderData: OrderFormData? {
        get { try? JSONDecoder().decode(OrderFormData.self, from: orderDataJSON) }
        set {
            if let newValue {
                orderDataJSON = (try? JSONEncoder().encode(newValue)) ?? Data()
                updatedAt = Date()
            }
        }
    }

    var customerName: String {
        orderData?.customerDisplayName ?? "Unknown"
    }

    var productSummary: String {
        orderData?.productSummary ?? ""
    }
}

enum SyncStatus: String, Codable, Sendable {
    case draft
    case pendingSync
    case syncing
    case partiallySynced
    case synced
    case failed

    var displayLabel: String {
        switch self {
        case .draft: "Draft"
        case .pendingSync: "Pending Sync"
        case .syncing: "Syncing..."
        case .partiallySynced: "Partially Synced"
        case .synced: "Synced"
        case .failed: "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .draft: "doc"
        case .pendingSync: "clock"
        case .syncing: "arrow.trianglehead.2.clockwise"
        case .partiallySynced: "exclamationmark.triangle"
        case .synced: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }
}
