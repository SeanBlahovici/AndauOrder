import Foundation

struct Customer: Codable, Sendable, Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var clinicName: String = ""
    var postalZipCode: String = ""
    var billingAddress: Address = Address()
    var shippingAddress: Address = Address()
    var shippingSameAsBilling: Bool = true
    var specialty: String = ""
    var currentlyUsing: String = "None"
    var isStudent: Bool = false
    var studentInfo: StudentInfo?

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var effectiveShippingAddress: Address {
        shippingSameAsBilling ? billingAddress : shippingAddress
    }
}

struct Address: Codable, Sendable, Equatable {
    var street: String = ""
    var street2: String = ""
    var city: String = ""
    var stateProvince: String = ""
    var postalZipCode: String = ""
    var country: String = "Canada"

    var isComplete: Bool {
        !street.isEmpty && !city.isEmpty && !stateProvince.isEmpty && !postalZipCode.isEmpty
    }

    var formatted: String {
        var lines = [street]
        if !street2.isEmpty { lines.append(street2) }
        lines.append("\(city), \(stateProvince) \(postalZipCode)")
        lines.append(country)
        return lines.joined(separator: "\n")
    }
}
