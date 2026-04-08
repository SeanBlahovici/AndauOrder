import Foundation

struct Prescription: Codable, Sendable, Equatable {
    // External Lens Distance
    var externalLensNear: Bool = false
    var externalLensMiddle: Bool = false
    var externalLensFar: Bool = false

    // Internal correction type
    var internalType: CorrectionType?

    // External correction type
    var externalType: ExternalCorrectionType?

    var currentEyeExam: Bool?
    var doWeHaveCopy: Bool?
    var contacts: Bool?
    var readers: Bool?

    var externalLensDistanceDescription: String {
        var items: [String] = []
        if externalLensNear { items.append("Near (Reading)") }
        if externalLensMiddle { items.append("Middle (Computer)") }
        if externalLensFar { items.append("Far (Distance)") }
        return items.isEmpty ? "None" : items.joined(separator: ", ")
    }
}

enum CorrectionType: String, Codable, Sendable, Identifiable {
    case regular = "Regular"
    case special = "Special"

    var id: String { rawValue }
}

enum ExternalCorrectionType: String, Codable, Sendable, Identifiable {
    case regular = "Regular"
    case special = "Special"
    case multiFocal = "Multi-Focal"

    var id: String { rawValue }
}
