import Foundation

struct ToolTime: Codable, Hashable, Sendable {
    let start: Double
    let end: Double?

    var startDate: Date { Date(timeIntervalSince1970: start / 1000) }
    var endDate: Date? { end.map { Date(timeIntervalSince1970: $0 / 1000) } }

    var duration: Duration? {
        guard let end else { return nil }
        return .milliseconds(Int(end - start))
    }
}
