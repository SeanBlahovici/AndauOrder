import Foundation

struct StudentInfo: Codable, Sendable, Equatable {
    var schoolName: String = ""
    var graduationDate: Date?
    var schoolIDPhotoData: Data?

    var isComplete: Bool {
        !schoolName.isEmpty
    }
}
