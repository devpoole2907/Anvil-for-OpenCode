import Foundation

struct ToolPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String
    let tool: String
    var state: ToolState
    let callID: String?
}
