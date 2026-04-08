import Foundation

struct BooksEstimateRequest: Encodable, Sendable {
    let customer_id: String
    let date: String
    let line_items: [BooksLineItem]
    let notes: String?
    let terms: String?
}

struct BooksLineItem: Encodable, Sendable {
    let name: String
    let description: String?
    let rate: Decimal
    let quantity: Int
}

struct BooksEstimateResponse: Decodable, Sendable {
    let code: Int
    let message: String
    let estimate: BooksEstimate
}

struct BooksEstimate: Decodable, Sendable {
    let estimate_id: String
    let estimate_number: String?
    let status: String
    let total: Double
}
