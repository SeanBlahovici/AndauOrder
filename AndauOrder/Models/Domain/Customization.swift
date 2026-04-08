import Foundation

struct Customization: Codable, Sendable, Equatable {
    var customEngraving: String = ""
    var workingDistanceInches: Double?
    var caseNumber: String = ""
    var picsTakenBy: String = "Michelle"
}
