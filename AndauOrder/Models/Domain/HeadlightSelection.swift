import Foundation

struct HeadlightSelection: Codable, Sendable, Equatable {
    var type: HeadlightType?
    var extraBattery: Bool = false
    var orchidCord3_5ft: Bool = false
    var orchidCord5ft: Bool = false

    var isSelected: Bool {
        type != nil
    }

    var displayDescription: String {
        guard let type else { return "None" }
        var parts = [type.rawValue]
        if extraBattery { parts.append("+ Extra Battery") }
        if orchidCord3_5ft { parts.append("+ 3.5ft Cord") }
        if orchidCord5ft { parts.append("+ 5ft Cord") }
        return parts.joined(separator: " ")
    }

    var accessoryItems: [(label: String, keyPath: WritableKeyPath<HeadlightSelection, Bool>)] {
        [
            ("Extra Battery", \.extraBattery),
            ("3.5 ft Orchid Cord", \.orchidCord3_5ft),
            ("5 ft Orchid Cord", \.orchidCord5ft),
        ]
    }
}

enum HeadlightType: String, Codable, CaseIterable, Sendable, Identifiable {
    case orchid = "Orchid"
    case orchidF = "Orchid-F"
    case orchidS = "Orchid-S"
    case orchidErgo = "Orchid Ergo"
    case external = "External"
    case orchidAntiCuringFilter = "Orchid Anti-Curing Filter"
    case studentOrchid = "Student Orchid"
    case butterflyEVO = "Butterfly EVO"
    case butterflySEVO = "Butterfly-S EVO"

    var id: String { rawValue }

    var category: String {
        switch self {
        case .orchid, .orchidF, .orchidS, .orchidErgo, .orchidAntiCuringFilter:
            "Orchid"
        case .external:
            "External"
        case .studentOrchid:
            "Student"
        case .butterflyEVO, .butterflySEVO:
            "Butterfly"
        }
    }
}
