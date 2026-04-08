import Foundation

enum FieldMappings {

    // MARK: - CRM Lead Fields

    /// Maps customer data from an order into Zoho CRM Lead field names.
    static func leadFields(from order: OrderFormData) -> [String: Any] {
        return [
            "Last_Name": order.customer.lastName,
            "First_Name": order.customer.firstName,
            "Email": order.customer.email,
            "Phone": order.customer.phone,
            "Company": order.customer.clinicName,
            "Street": order.customer.billingAddress.street,
            "City": order.customer.billingAddress.city,
            "State": order.customer.billingAddress.stateProvince,
            "Zip_Code": order.customer.billingAddress.postalZipCode,
            "Country": order.customer.billingAddress.country,
        ]
    }

    // MARK: - Deal Name

    /// Builds a deal name from the customer name and loupe selection description.
    static func dealName(from order: OrderFormData) -> String {
        "\(order.customer.fullName) - \(order.loupeSelection.displayDescription)"
    }

    // MARK: - Estimate Line Items

    /// Converts all selected products and pricing into Zoho Books line items.
    static func estimateLineItems(from order: OrderFormData) -> [BooksLineItem] {
        var items: [BooksLineItem] = []

        // Loupes
        if order.loupeSelection.isSelected {
            let description = [
                order.loupeSelection.style?.rawValue,
                order.loupeSelection.frame?.rawValue,
                order.loupeSelection.size?.rawValue,
                order.loupeSelection.color,
            ]
            .compactMap { $0 }
            .joined(separator: " ")

            items.append(BooksLineItem(
                name: description,
                description: nil,
                rate: order.pricing.loupes,
                quantity: 1
            ))
        }

        // Internal Correction
        if let internalType = order.prescription.internalType {
            items.append(BooksLineItem(
                name: "Internal Correction - \(internalType.rawValue)",
                description: nil,
                rate: order.pricing.internalCorrection,
                quantity: 1
            ))
        }

        // External Correction
        if let externalType = order.prescription.externalType {
            items.append(BooksLineItem(
                name: "External Correction - \(externalType.rawValue)",
                description: nil,
                rate: order.pricing.externalCorrection,
                quantity: 1
            ))
        }

        // Headlight
        if order.headlightSelection.isSelected {
            var accessoryParts: [String] = []
            if order.headlightSelection.extraBattery { accessoryParts.append("Extra Battery") }
            if order.headlightSelection.orchidCord3_5ft { accessoryParts.append("3.5ft Cord") }
            if order.headlightSelection.orchidCord5ft { accessoryParts.append("5ft Cord") }

            let accessoriesDescription = accessoryParts.isEmpty
                ? nil
                : accessoryParts.joined(separator: ", ")

            items.append(BooksLineItem(
                name: order.headlightSelection.type?.rawValue ?? "Headlight",
                description: accessoriesDescription,
                rate: order.pricing.light,
                quantity: 1
            ))
        }

        // Flamingo
        if order.pricing.flamingo != 0 {
            items.append(BooksLineItem(
                name: "Flamingo",
                description: nil,
                rate: order.pricing.flamingo,
                quantity: 1
            ))
        }

        // Laser Inserts
        if order.pricing.laserInserts != 0 {
            items.append(BooksLineItem(
                name: "Laser Inserts",
                description: nil,
                rate: order.pricing.laserInserts,
                quantity: 1
            ))
        }

        // Adapters
        if order.adapterSelection.isSelected {
            items.append(BooksLineItem(
                name: order.adapterSelection.displayDescription,
                description: nil,
                rate: order.pricing.adapters,
                quantity: 1
            ))
        }

        // Shipping
        if order.pricing.shipping != 0 {
            items.append(BooksLineItem(
                name: "Shipping",
                description: nil,
                rate: order.pricing.shipping,
                quantity: 1
            ))
        }

        // Promotion Discount (negative value)
        if order.pricing.lessPromotion != 0 {
            items.append(BooksLineItem(
                name: "Promotion Discount",
                description: nil,
                rate: order.pricing.lessPromotion,
                quantity: 1
            ))
        }

        return items
    }

    // MARK: - Estimate Notes

    /// Builds the notes section for a Zoho Books estimate, including Michelle's contact info
    /// and any additional order notes.
    static func estimateNotes(from order: OrderFormData, defaults: UserDefaults = .standard) -> String {
        let email = defaults.string(forKey: "michelleEmail") ?? ""
        let phone = defaults.string(forKey: "michellePhone") ?? ""

        var lines: [String] = []
        lines.append("Contact: Michelle Fontaine")
        if !email.isEmpty { lines.append("Email: \(email)") }
        if !phone.isEmpty { lines.append("Phone: \(phone)") }

        if !order.otherNotes.isEmpty {
            lines.append("")
            lines.append(order.otherNotes)
        }

        return lines.joined(separator: "\n")
    }
}
