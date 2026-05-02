import Foundation

struct ReasoningPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String
    var text: String
    var time: PartTime?
}
