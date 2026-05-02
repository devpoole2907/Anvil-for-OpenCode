import Foundation

struct MessageTime: Codable, Hashable, Sendable {
    let created: Double
    let completed: Double?

    var createdDate: Date { Date(timeIntervalSince1970: created / 1000) }
    var completedDate: Date? { completed.map { Date(timeIntervalSince1970: $0 / 1000) } }
}
