import Foundation

struct Todo: Codable, Identifiable, Hashable, Sendable {
    var id: String { content }
    let content: String
    let status: String
    let priority: String?

    enum Status {
        case pending, inProgress, completed, unknown
    }

    var resolvedStatus: Status {
        switch status {
        case "pending": .pending
        case "in_progress": .inProgress
        case "completed": .completed
        default: .unknown
        }
    }
}
