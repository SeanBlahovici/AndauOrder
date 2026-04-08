import Foundation
import SwiftData

@Model
final class SyncQueueEntry {
    @Attribute(.unique) var id: UUID
    var orderID: UUID
    var stepTypeRaw: String
    var stepOrder: Int
    var statusRaw: String
    var requestPayload: Data?
    var responsePayload: Data?
    var zohoRecordID: String?
    var createdAt: Date
    var attemptCount: Int
    var lastError: String?

    init(orderID: UUID, stepType: SyncStepType, stepOrder: Int) {
        self.id = UUID()
        self.orderID = orderID
        self.stepTypeRaw = stepType.rawValue
        self.stepOrder = stepOrder
        self.statusRaw = SyncStepStatus.pending.rawValue
        self.createdAt = Date()
        self.attemptCount = 0
    }

    var stepType: SyncStepType {
        get { SyncStepType(rawValue: stepTypeRaw) ?? .createLead }
        set { stepTypeRaw = newValue.rawValue }
    }

    var status: SyncStepStatus {
        get { SyncStepStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}

enum SyncStepType: String, Codable, Sendable {
    case createLead
    case transitionLeadToTMReachedOut
    case transitionLeadToCustomerEngaged
    case fetchCreatedRecords
    case transitionDealToQualified
    case updateDealDetails
    case createBooksCustomer
    case createEstimate

    var displayLabel: String {
        switch self {
        case .createLead: "Create Lead"
        case .transitionLeadToTMReachedOut: "Transition: TM Reached Out"
        case .transitionLeadToCustomerEngaged: "Transition: Customer Engaged"
        case .fetchCreatedRecords: "Fetch Created Records"
        case .transitionDealToQualified: "Transition: Qualified"
        case .updateDealDetails: "Update Deal Details"
        case .createBooksCustomer: "Create Books Customer"
        case .createEstimate: "Create Estimate"
        }
    }
}

enum SyncStepStatus: String, Codable, Sendable {
    case pending
    case inProgress
    case completed
    case failed
    case skipped
}
