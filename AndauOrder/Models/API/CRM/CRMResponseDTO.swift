import Foundation

struct CRMResponse<T: Decodable>: Decodable, Sendable where T: Sendable {
    let data: [CRMRecord<T>]?
}

struct CRMRecord<T: Decodable>: Decodable, Sendable where T: Sendable {
    let code: String?
    let status: String?
    let message: String?
    let details: T?
}

struct CRMRecordID: Decodable, Sendable {
    let id: String
}
