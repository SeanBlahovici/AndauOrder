import SwiftUI

struct OrderPDFView: View {
    let formData: OrderFormData

    private let pageWidth: CGFloat = 612 // US Letter
    private let pageHeight: CGFloat = 792

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            customerBlock
            Divider()
            productsBlock
            Divider()
            customizationBlock
            Divider()
            pricingTable
            if formData.signatureImageData != nil {
                Divider()
                signatureBlock
            }
            Spacer()
            footer
        }
        .padding(40)
        .frame(width: pageWidth, height: pageHeight, alignment: .topLeading)
        .background(.white)
        .foregroundStyle(.black)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Andau Medical")
                    .font(.title2.bold())
                Text("Order Summary")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Date: \(formatDate(formData.date))")
                    .font(.caption)
                Text("Order: \(formData.id.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Customer

    @ViewBuilder
    private var customerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Customer Information")
                .font(.headline)

            pdfRow("Name", formData.customer.fullName)
            pdfRow("Email", formData.customer.email)
            pdfRow("Phone", formData.customer.phone)
            pdfRow("Clinic", formData.customer.clinicName)
            if !formData.customer.specialty.isEmpty {
                pdfRow("Specialty", formData.customer.specialty)
            }
            if formData.customer.isStudent {
                pdfRow("Student", "Yes")
                if let info = formData.customer.studentInfo {
                    pdfRow("School", info.schoolName)
                }
            }

            if formData.customer.billingAddress.isComplete {
                Text("Billing Address:")
                    .font(.caption.bold())
                    .padding(.top, 4)
                Text(formData.customer.billingAddress.formatted)
                    .font(.caption)
            }

            if !formData.customer.shippingSameAsBilling,
               formData.customer.shippingAddress.isComplete {
                Text("Shipping Address:")
                    .font(.caption.bold())
                    .padding(.top, 4)
                Text(formData.customer.shippingAddress.formatted)
                    .font(.caption)
            }
        }
    }

    // MARK: - Products

    @ViewBuilder
    private var productsBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Products")
                .font(.headline)

            if formData.loupeSelection.isSelected {
                pdfRow("Loupes", formData.loupeSelection.displayDescription)
            }
            if formData.headlightSelection.isSelected {
                var desc = formData.headlightSelection.type?.rawValue ?? ""
                let _ = {
                    var accessories: [String] = []
                    if formData.headlightSelection.extraBattery { accessories.append("Extra Battery") }
                    if formData.headlightSelection.orchidCord3_5ft { accessories.append("3.5ft Cord") }
                    if formData.headlightSelection.orchidCord5ft { accessories.append("5ft Cord") }
                    if !accessories.isEmpty { desc += " (\(accessories.joined(separator: ", ")))" }
                }()
                pdfRow("Headlight", desc)
            }
            if formData.ppeSelection.sideShield {
                pdfRow("PPE", "Side Shield")
            }
            if formData.ppeSelection.laserProtection {
                pdfRow("PPE", "Laser Protection")
            }
            if formData.adapterSelection.isSelected {
                pdfRow("Adapter", formData.adapterSelection.displayDescription)
            }
            if !formData.otherNotes.isEmpty {
                pdfRow("Notes", formData.otherNotes)
            }
        }
    }

    // MARK: - Customization

    @ViewBuilder
    private var customizationBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Customization & Rx")
                .font(.headline)

            if !formData.customization.customEngraving.isEmpty {
                pdfRow("Engraving", formData.customization.customEngraving)
            }
            if let wd = formData.customization.workingDistanceInches {
                pdfRow("Working Distance", "\(wd)\"")
            }
            if let rxType = formData.prescription.internalType {
                pdfRow("Internal Rx", rxType.rawValue)
            }
            if let rxType = formData.prescription.externalType {
                pdfRow("External Rx", rxType.rawValue)
            }
        }
    }

    // MARK: - Pricing

    @ViewBuilder
    private var pricingTable: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pricing")
                .font(.headline)

            let lineItems = FieldMappings.estimateLineItems(from: formData)
            ForEach(Array(lineItems.enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.name)
                        .font(.caption)
                    Spacer()
                    Text(formatCurrency(item.rate))
                        .font(.caption)
                        .monospacedDigit()
                }
            }

            Divider()

            HStack {
                Text("Subtotal")
                    .font(.caption.bold())
                Spacer()
                Text(formatCurrency(formData.pricing.subtotal))
                    .font(.caption.bold())
                    .monospacedDigit()
            }
            HStack {
                Text("Tax (14.975%)")
                    .font(.caption)
                Spacer()
                Text(formatCurrency(formData.pricing.tax))
                    .font(.caption)
                    .monospacedDigit()
            }
            HStack {
                Text("Total (CAD)")
                    .font(.subheadline.bold())
                Spacer()
                Text(formatCurrency(formData.pricing.total))
                    .font(.subheadline.bold())
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Signature

    @ViewBuilder
    private var signatureBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Signature")
                .font(.headline)
            if let sigData = formData.signatureImageData {
                #if os(macOS)
                if let nsImage = NSImage(data: sigData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                }
                #else
                if let uiImage = UIImage(data: sigData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                }
                #endif
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            Divider()
            let email = UserDefaults.standard.string(forKey: "michelleEmail") ?? ""
            let phone = UserDefaults.standard.string(forKey: "michellePhone") ?? ""
            Text("Territory Manager: Michelle Fontaine")
                .font(.caption)
            if !email.isEmpty {
                Text("Email: \(email)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !phone.isEmpty {
                Text("Phone: \(phone)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func pdfRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption.bold())
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.caption)
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.locale = Locale(identifier: "en_CA")
        return formatter.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
