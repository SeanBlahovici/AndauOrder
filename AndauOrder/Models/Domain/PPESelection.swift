import Foundation

struct PPESelection: Codable, Sendable, Equatable {
    var sideShield: Bool = false
    var laserProtection: Bool = false

    var isSelected: Bool {
        sideShield || laserProtection
    }

    var displayDescription: String {
        var items: [String] = []
        if sideShield { items.append("Side Shield") }
        if laserProtection { items.append("Laser Protection") }
        return items.isEmpty ? "None" : items.joined(separator: ", ")
    }
}
