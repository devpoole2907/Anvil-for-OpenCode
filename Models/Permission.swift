import Foundation

struct Permission: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String?
    let callID: String?
    let type: String
    let pattern: String?
    let metadata: AnyCodable?
    let time: PermissionTime
}

struct PermissionTime: Codable, Hashable, Sendable {
    let created: Double
}
