import Foundation

struct AdapterSelection: Codable, Sendable, Equatable {
    var type: AdapterType?
    var competitorAdapterDetail: String = ""

    var isSelected: Bool {
        type != nil
    }

    var displayDescription: String {
        guard let type else { return "None" }
        if type == .competitorAdapter, !competitorAdapterDetail.isEmpty {
            return "\(type.rawValue): \(competitorAdapterDetail)"
        }
        return type.rawValue
    }
}

enum AdapterType: String, Codable, CaseIterable, Sendable, Identifiable {
    case semiUniversalSport = "Semi-Universal Sport"
    case semiUniversalMetal = "Semi-Universal Metal"
    case universalClip = "Universal Clip"
    case competitorAdapter = "Competitor Adapter"

    var id: String { rawValue }
}
