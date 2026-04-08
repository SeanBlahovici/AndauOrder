import Foundation

struct OrderFormData: Codable, Sendable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var territoryManager: String = "Michelle Fontaine"

    // Customer info (page 1 top)
    var customer: Customer = Customer()

    // Product selections (page 1 bottom)
    var loupeSelection: LoupeSelection = LoupeSelection()
    var headlightSelection: HeadlightSelection = HeadlightSelection()
    var ppeSelection: PPESelection = PPESelection()
    var adapterSelection: AdapterSelection = AdapterSelection()
    var otherNotes: String = ""

    // Customization & Prescription (page 2 top)
    var customization: Customization = Customization()
    var prescription: Prescription = Prescription()

    // Pricing (page 2 right)
    var pricing: OrderPricing = OrderPricing()

    // Review checklist (page 2 left)
    var reviewChecklist: ReviewChecklist = ReviewChecklist()

    // Payment & closing (page 2 bottom)
    var nameOnCard: String = ""
    var referralSources: Set<ReferralSource> = []
    var isPaid: Bool?
    var paymentType: PaymentType?
    var signatureImageData: Data?

    // Computed helpers
    var customerDisplayName: String {
        customer.fullName.isEmpty ? "New Order" : customer.fullName
    }

    var productSummary: String {
        var items: [String] = []
        if loupeSelection.isSelected { items.append(loupeSelection.displayDescription) }
        if headlightSelection.isSelected { items.append(headlightSelection.type?.rawValue ?? "") }
        return items.isEmpty ? "No products selected" : items.joined(separator: " + ")
    }
}

// MARK: - Supporting Enums

enum ReferralSource: String, Codable, CaseIterable, Sendable, Identifiable {
    case colleague = "Colleague"
    case socialMedia = "Social Media"
    case lectureOrCE = "Lecture or CE"
    case kolAmbassador = "KOL/Ambassador"

    var id: String { rawValue }
}

enum PaymentType: String, Codable, Sendable, Identifiable {
    case paidFull = "Paid Full"
    case paymentPlan = "P.Plan"

    var id: String { rawValue }
}
