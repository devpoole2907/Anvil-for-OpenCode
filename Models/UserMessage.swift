import Foundation

struct UserMessage: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let role: String
    let sessionID: String
    let time: MessageTime
}
