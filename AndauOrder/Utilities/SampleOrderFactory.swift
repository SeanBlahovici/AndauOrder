import Foundation

#if DEBUG
enum SampleOrderFactory {
    static func create() -> OrderFormData {
        var order = OrderFormData()
        order.date = Date()
        order.territoryManager = "Michelle Fontaine"

        // Customer - fully filled
        var customer = Customer()
        customer.firstName = "Jean-Pierre"
        customer.lastName = "Tremblay"
        customer.email = "jptremblay@testclinic.ca"
        customer.phone = "514-555-0123"
        customer.clinicName = "Clinique Dentaire Tremblay"
        customer.postalZipCode = "H2X 1Y4"
        customer.billingAddress = Address(
            street: "1234 Rue Sainte-Catherine",
            street2: "Suite 200",
            city: "Montreal",
            stateProvince: "Quebec",
            postalZipCode: "H2X 1Y4",
            country: "Canada"
        )
        customer.shippingSameAsBilling = true
        customer.specialty = "General Dentistry"
        customer.currentlyUsing = "Orascoptic 3.5x"
        customer.isStudent = false
        customer.studentInfo = nil
        order.customer = customer

        // Loupe selection - Ergo 4.0x on Blues frame
        order.loupeSelection = LoupeSelection(
            style: .ergo4_0x,
            frame: .blues,
            size: .large,
            color: "Blue"
        )

        // Headlight - Orchid with extras
        order.headlightSelection = HeadlightSelection(
            type: .orchid,
            extraBattery: true,
            orchidCord3_5ft: false,
            orchidCord5ft: true
        )

        // PPE
        order.ppeSelection = PPESelection(
            sideShield: true,
            laserProtection: false
        )

        // Adapter
        order.adapterSelection = AdapterSelection(
            type: .semiUniversalMetal,
            competitorAdapterDetail: ""
        )

        // Other notes
        order.otherNotes = "Test order — do not ship. Conference demo."

        // Customization
        order.customization = Customization(
            customEngraving: "Dr. JP Tremblay",
            workingDistanceInches: 16.0,
            caseNumber: "TC-2026-001",
            picsTakenBy: "Michelle"
        )

        // Prescription
        var prescription = Prescription()
        prescription.externalLensNear = true
        prescription.externalLensMiddle = false
        prescription.externalLensFar = false
        prescription.internalType = .regular
        prescription.externalType = nil
        prescription.currentEyeExam = true
        prescription.doWeHaveCopy = true
        prescription.contacts = false
        prescription.readers = true
        order.prescription = prescription

        // Pricing - realistic numbers
        var pricing = OrderPricing()
        pricing.loupes = 2495
        pricing.internalCorrection = 200
        pricing.externalCorrection = 0
        pricing.light = 1160
        pricing.flamingo = 0
        pricing.laserInserts = 0
        pricing.adapters = 195
        pricing.shipping = 50
        pricing.lessPromotion = -100
        pricing.taxRate = Decimal(string: "0.14975")! // Quebec GST+QST
        order.pricing = pricing

        // Review checklist - all checked
        var checklist = ReviewChecklist()
        checklist.paymentPlanOptions = true
        checklist.onlineSupportPortal = true
        checklist.customerJourneyEmails = true
        checklist.threeMonthCustomizedSupport = true
        checklist.warrantyPolicy = true
        checklist.prescriptionNeedsAssessed = true
        checklist.leadTimeExpectations = true
        checklist.learningCurveSupport = true
        checklist.shippingAndHandling = true
        checklist.laserInserts = true
        checklist.staErgoFingerPerioPlus = true
        checklist.upgradeCase = true
        checklist.lightingSystemsFinalSale = true
        checklist.taxes = true
        order.reviewChecklist = checklist

        // Payment
        order.nameOnCard = "Jean-Pierre Tremblay"
        order.referralSources = [.colleague, .lectureOrCE]
        order.isPaid = true
        order.paymentType = .paidFull

        return order
    }
}
#endif
