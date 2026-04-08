import Foundation

enum ZohoEnvironment: String, Sendable {
    case sandbox
    case production

    var accountsURL: String {
        "https://accounts.zoho.com"
    }

    var crmBaseURL: String {
        switch self {
        case .sandbox: "https://sandbox.zohoapis.com/crm/v8"
        case .production: "https://www.zohoapis.com/crm/v8"
        }
    }

    var booksBaseURL: String {
        switch self {
        case .sandbox: "https://sandbox.zohoapis.com/books/v3"
        case .production: "https://www.zohoapis.com/books/v3"
        }
    }
}
