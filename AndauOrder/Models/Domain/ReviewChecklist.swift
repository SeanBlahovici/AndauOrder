import Foundation

struct ReviewChecklist: Codable, Sendable, Equatable {
    var paymentPlanOptions: Bool = false
    var onlineSupportPortal: Bool = false
    var customerJourneyEmails: Bool = false
    var threeMonthCustomizedSupport: Bool = false
    var warrantyPolicy: Bool = false
    var prescriptionNeedsAssessed: Bool = false
    var leadTimeExpectations: Bool = false
    var learningCurveSupport: Bool = false
    var shippingAndHandling: Bool = false
    var laserInserts: Bool = false
    var staErgoFingerPerioPlus: Bool = false
    var upgradeCase: Bool = false
    var lightingSystemsFinalSale: Bool = false
    var taxes: Bool = false

    var completedCount: Int {
        allItems.filter(\.value).count
    }

    var totalCount: Int {
        allItems.count
    }

    var isComplete: Bool {
        completedCount == totalCount
    }

    var allItems: [(label: String, value: Bool, keyPath: WritableKeyPath<ReviewChecklist, Bool>)] {
        [
            ("Payment Plan Options", paymentPlanOptions, \.paymentPlanOptions),
            ("Online Support Portal", onlineSupportPortal, \.onlineSupportPortal),
            ("Customer Journey Emails", customerJourneyEmails, \.customerJourneyEmails),
            ("3-Month Customized Support", threeMonthCustomizedSupport, \.threeMonthCustomizedSupport),
            ("Warranty Policy", warrantyPolicy, \.warrantyPolicy),
            ("Prescription Needs Assessed", prescriptionNeedsAssessed, \.prescriptionNeedsAssessed),
            ("Lead Time Expectations & Next Steps", leadTimeExpectations, \.leadTimeExpectations),
            ("Learning Curve Support", learningCurveSupport, \.learningCurveSupport),
            ("Shipping & Handling", shippingAndHandling, \.shippingAndHandling),
            ("Laser Inserts", laserInserts, \.laserInserts),
            ("STA / ErgoFinger / PerioPlus (Canada)", staErgoFingerPerioPlus, \.staErgoFingerPerioPlus),
            ("Upgrade Case", upgradeCase, \.upgradeCase),
            ("Lighting Systems Final Sale", lightingSystemsFinalSale, \.lightingSystemsFinalSale),
            ("Taxes", taxes, \.taxes),
        ]
    }
}
