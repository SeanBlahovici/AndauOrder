import Foundation

enum ZohoEnvironment: String, Sendable {
    case sandbox
    case production

    var accountsURL: String {
        switch self {
        case .sandbox: "https://accounts.zohocloud.ca"
        case .production: "https://accounts.zohocloud.ca"
        }
    }

    var crmBaseURL: String {
        switch self {
        case .sandbox: "https://sandbox.zohoapis.ca/crm/v8"
        case .production: "https://www.zohoapis.ca/crm/v8"
        }
    }

    var booksBaseURL: String {
        switch self {
        case .sandbox: "https://sandbox.zohoapis.ca/books/v3"
        case .production: "https://www.zohoapis.ca/books/v3"
        }
    }
}
