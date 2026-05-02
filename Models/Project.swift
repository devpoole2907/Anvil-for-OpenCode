import Foundation

struct Project: Codable, Identifiable, Hashable, Sendable, Comparable {
    let id: String
    let worktree: String
    let name: String?
    let time: TimeRange

    var directory: String { worktree }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return URL(fileURLWithPath: worktree).lastPathComponent
    }

    static func < (lhs: Project, rhs: Project) -> Bool {
        lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
    }
}
