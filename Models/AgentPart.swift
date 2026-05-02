import Foundation

struct AgentPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String
    let name: String
    let source: AgentPartSource?
}

struct AgentPartSource: Codable, Hashable, Sendable {
    let start: Int
    let end: Int
    let value: String?
}
