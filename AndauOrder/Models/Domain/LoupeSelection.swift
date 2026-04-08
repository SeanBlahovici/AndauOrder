import Foundation

struct LoupeSelection: Codable, Sendable, Equatable {
    var style: LoupeStyle?
    var frame: FrameModel?
    var size: FrameSize?
    var color: String?

    var isSelected: Bool {
        style != nil
    }

    var displayDescription: String {
        guard let style else { return "None" }
        var parts = [style.rawValue]
        if let frame { parts.append(frame.rawValue) }
        if let size { parts.append(size.rawValue) }
        if let color { parts.append(color) }
        return parts.joined(separator: " - ")
    }
}

// MARK: - Loupe Style

enum LoupeStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    case ergoV = "ErgoV"
    case ergoVPro = "ErgoV Pro"
    case ergo3_0x = "Ergo 3.0x"
    case ergo4_0x = "Ergo 4.0x"
    case ergo5_0x = "Ergo 5.0x"
    case ergo6_0x = "Ergo 6.0x"
    case ergo7_5x = "Ergo 7.5x"
    case ergo10x = "Ergo 10x"
    case galilean2_5x = "Galilean 2.5x"
    case galilean2_7x = "Galilean 2.7x"
    case galilean3_2x = "Galilean 3.2x"
    case prismatic4_0x = "Prismatic 4.0x"
    case prismatic4_8x = "Prismatic 4.8x"
    case prismatic5_5x = "Prismatic 5.5x"

    var id: String { rawValue }

    var category: String {
        switch self {
        case .ergoV, .ergoVPro: "Ergo V"
        case .ergo3_0x, .ergo4_0x, .ergo5_0x, .ergo6_0x, .ergo7_5x, .ergo10x: "Ergo"
        case .galilean2_5x, .galilean2_7x, .galilean3_2x: "Galilean"
        case .prismatic4_0x, .prismatic4_8x, .prismatic5_5x: "Prismatic"
        }
    }
}

// MARK: - Frame Model

enum FrameModel: String, Codable, CaseIterable, Sendable, Identifiable {
    case indie = "Indie"
    case blues = "Blues"
    case soul = "Soul"
    case jazz = "Jazz"
    case sport = "Sport"
    case progear = "Progear"
    case bolle = "Bolle"

    var id: String { rawValue }

    var availableSizes: [FrameSize] {
        switch self {
        case .indie, .blues, .jazz, .sport:
            [.medium, .large, .extraLarge]
        case .soul:
            [.medium, .large]
        case .progear, .bolle:
            [] // One-size
        }
    }

    var availableColors: [String] {
        switch self {
        case .indie:
            ["Blue", "Black", "Lava", "Champagne", "Turquoise", "Green"]
        case .blues:
            ["Blue", "Black", "Bronze", "Pink", "Burgundy", "Turquoise", "RG", "Purple"]
        case .soul:
            ["Brown", "Black", "Pink", "Turquoise", "Burgundy", "White"]
        case .jazz:
            ["Blue", "Orange", "Red", "Turquoise", "Green"]
        case .sport:
            ["Black", "Blue", "Grey", "Red", "Rose-Gold", "White"]
        case .progear:
            ["White/Blue", "Red/Grey", "Black", "White/Green"]
        case .bolle:
            ["Gunmetal"]
        }
    }

    var requiresSize: Bool {
        !availableSizes.isEmpty
    }
}

// MARK: - Frame Size

enum FrameSize: String, Codable, CaseIterable, Sendable, Identifiable {
    case medium = "M"
    case large = "L"
    case extraLarge = "XL"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        }
    }
}
