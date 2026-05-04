import Foundation

enum Part: Codable, Identifiable, Hashable, Sendable {
    case text(TextPart)
    case reasoning(ReasoningPart)
    case tool(ToolPart)
    case compaction(CompactionPart)
    case file(FilePart)
    case agent(AgentPart)
    case unknown(type: String, id: String, raw: AnyCodable)

    var id: String {
        switch self {
        case .text(let p): p.id
        case .reasoning(let p): p.id
        case .tool(let p): p.id
        case .compaction(let p): p.id
        case .file(let p): p.id
        case .agent(let p): p.id
        case .unknown(_, let id, _): id
        }
    }

    var sessionID: String {
        switch self {
        case .text(let p): p.sessionID
        case .reasoning(let p): p.sessionID
        case .tool(let p): p.sessionID
        case .compaction(let p): p.sessionID
        case .file(let p): p.sessionID
        case .agent(let p): p.sessionID
        case .unknown: ""
        }
    }

    var messageID: String {
        switch self {
        case .text(let p): p.messageID
        case .reasoning(let p): p.messageID
        case .tool(let p): p.messageID
        case .compaction(let p): p.messageID
        case .file(let p): p.messageID
        case .agent(let p): p.messageID
        case .unknown: ""
        }
    }

    var textLength: Int {
        switch self {
        case .text(let p): p.text.count
        case .reasoning(let p): p.text.count
        default: 0
        }
    }

    var typeString: String {
        switch self {
        case .text: "text"
        case .reasoning: "reasoning"
        case .tool: "tool"
        case .compaction: "compaction"
        case .file: "file"
        case .agent: "agent"
        case .unknown(let type, _, _): type
        }
    }

    private enum CodingKeys: String, CodingKey { case type, id }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try TextPart(from: decoder))
        case "reasoning":
            self = .reasoning(try ReasoningPart(from: decoder))
        case "tool":
            self = .tool(try ToolPart(from: decoder))
        case "step-start", "step-finish":
            // NOTE: Step boundary parts are not rendered in v1; preserve their payload for forward compatibility.
            let raw = try AnyCodable(from: decoder)
            let id = (try? container.decode(String.self, forKey: .id)) ?? "step-\(UUID().uuidString)"
            self = .unknown(type: type, id: id, raw: raw)
        case "compaction":
            self = .compaction(try CompactionPart(from: decoder))
        case "file":
            self = .file(try FilePart(from: decoder))
        case "agent":
            self = .agent(try AgentPart(from: decoder))
        default:
            let raw = try AnyCodable(from: decoder)
            let id = (try? container.decode(String.self, forKey: .id)) ?? "unknown-\(UUID().uuidString)"
            self = .unknown(type: type, id: id, raw: raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let p): try p.encode(to: encoder)
        case .reasoning(let p): try p.encode(to: encoder)
        case .tool(let p): try p.encode(to: encoder)
        case .compaction(let p): try p.encode(to: encoder)
        case .file(let p): try p.encode(to: encoder)
        case .agent(let p): try p.encode(to: encoder)
        case .unknown(_, _, let raw): try raw.encode(to: encoder)
        }
    }
}
