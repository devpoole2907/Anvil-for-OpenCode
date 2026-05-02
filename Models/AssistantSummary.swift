import Foundation

struct AssistantSummary: Codable, Hashable, Sendable {
    let diffs: [FileDiff]?
}
