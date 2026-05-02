import Foundation

struct TimeRange: Codable, Hashable, Sendable {
    let created: Double
    let updated: Double

    var createdDate: Date { Date(timeIntervalSince1970: created / 1000) }
    var updatedDate: Date { Date(timeIntervalSince1970: updated / 1000) }
}
