import Foundation

struct BlueprintResponse: Decodable, Sendable {
    let blueprint: BlueprintData
}

struct BlueprintData: Decodable, Sendable {
    let transitions: [BlueprintTransition]
}

struct BlueprintTransition: Decodable, Sendable {
    let id: String
    let name: String
    let next_field_value: String?
}
