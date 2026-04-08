import Foundation

struct BooksContactRequest: Encodable, Sendable {
    let contact_name: String
    let company_name: String?
    let contact_type: String // "customer"
    let email: String?
    let phone: String?
    let billing_address: BooksAddress?
    let shipping_address: BooksAddress?
}

struct BooksAddress: Codable, Sendable {
    let attention: String?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
}

struct BooksContactResponse: Decodable, Sendable {
    let code: Int
    let message: String
    let contact: BooksContact
}

struct BooksContact: Decodable, Sendable {
    let contact_id: String
    let contact_name: String
}
