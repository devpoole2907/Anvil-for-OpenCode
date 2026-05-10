import Foundation

struct ConfigInfo: Decodable, Sendable {
    let model: String?
    let theme: String?
    let agents: AnyCodable?
    var mcpServers: [String: MCPConfig]?

    private enum CodingKeys: String, CodingKey {
        case model
        case theme
        case agents
        case mcpServers
        case mcp_servers
        case mcp
    }

    init(
        model: String? = nil,
        theme: String? = nil,
        agents: AnyCodable? = nil,
        mcpServers: [String : MCPConfig]? = nil
    ) {
        self.model = model
        self.theme = theme
        self.agents = agents
        self.mcpServers = mcpServers
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        model = try container.decodeIfPresent(String.self, forKey: .model)
        theme = try container.decodeIfPresent(String.self, forKey: .theme)
        agents = try container.decodeIfPresent(AnyCodable.self, forKey: .agents)
        mcpServers =
            try container.decodeIfPresent([String: MCPConfig].self, forKey: .mcpServers)
            ?? container.decodeIfPresent([String: MCPConfig].self, forKey: .mcp_servers)
            ?? container.decodeIfPresent([String: MCPConfig].self, forKey: .mcp)
    }
}

struct MCPConfig: Codable, Sendable {
    var type: String?
    var enabled: Bool?
    var disabled: Bool?
    var command: [String]?
    var args: [String]?
    var alwaysAllow: [String]?

    private enum CodingKeys: String, CodingKey {
        case type
        case enabled
        case disabled
        case command
        case args
        case alwaysAllow
        case always_allow
    }

    init(
        type: String? = nil,
        enabled: Bool? = nil,
        disabled: Bool? = nil,
        command: [String]? = nil,
        args: [String]? = nil,
        alwaysAllow: [String]? = nil
    ) {
        self.type = type
        self.enabled = enabled
        self.disabled = disabled
        self.command = command
        self.args = args
        self.alwaysAllow = alwaysAllow
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        if let commandParts = try container.decodeIfPresent([String].self, forKey: .command) {
            command = commandParts
        } else if let commandString = try container.decodeIfPresent(String.self, forKey: .command) {
            command = [commandString]
        } else {
            command = nil
        }
        args = try container.decodeIfPresent([String].self, forKey: .args)
        alwaysAllow =
            try container.decodeIfPresent([String].self, forKey: .alwaysAllow)
            ?? container.decodeIfPresent([String].self, forKey: .always_allow)

        if disabled == nil, let enabled {
            disabled = !enabled
        }
        if enabled == nil, let disabled {
            enabled = !disabled
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(alwaysAllow, forKey: .alwaysAllow)
    }
}
