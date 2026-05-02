import Foundation

struct CompactionPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String
    let time: PartTime?
}
