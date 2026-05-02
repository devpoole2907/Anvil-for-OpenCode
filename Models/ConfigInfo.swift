import Foundation

struct ConfigInfo: Codable, Sendable {
    let model: String?
    let theme: String?
    let agents: AnyCodable?
    var mcpServers: [String: MCPConfig]?
}

struct MCPConfig: Codable, Sendable {
    var disabled: Bool?
    var command: String?
    var args: [String]?
    var alwaysAllow: [String]?
}
