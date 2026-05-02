import Foundation

struct Session: Codable, Identifiable, Hashable, Sendable, Comparable {
    let id: String
    var title: String?
    let parentID: String?
    let projectID: String?
    let directory: String?
    let time: TimeRange
    let revert: SessionRevertInfo?
    let share: SessionShareInfo?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return "Untitled session"
    }

    /// Sort by most-recently-updated first.
    static func < (lhs: Session, rhs: Session) -> Bool {
        lhs.time.updated > rhs.time.updated
    }
}

struct SessionRevertInfo: Codable, Hashable, Sendable {
    let messageID: String
    let partID: String?
}

struct SessionShareInfo: Codable, Hashable, Sendable {
    let url: String
}
