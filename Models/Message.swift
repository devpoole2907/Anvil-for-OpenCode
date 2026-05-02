import Foundation

enum Message: Codable, Identifiable, Hashable, Sendable {
    case user(UserMessage)
    case assistant(AssistantMessage)

    var id: String {
        switch self {
        case .user(let m): m.id
        case .assistant(let m): m.id
        }
    }

    var sessionID: String {
        switch self {
        case .user(let m): m.sessionID
        case .assistant(let m): m.sessionID
        }
    }

    var time: MessageTime {
        switch self {
        case .user(let m): m.time
        case .assistant(let m): m.time
        }
    }

    var role: String {
        switch self {
        case .user: "user"
        case .assistant: "assistant"
        }
    }

    private enum CodingKeys: String, CodingKey { case role }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let role = try container.decode(String.self, forKey: .role)
        switch role {
        case "user":
            self = .user(try UserMessage(from: decoder))
        case "assistant":
            self = .assistant(try AssistantMessage(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .role,
                in: container,
                debugDescription: "Unknown message role: \(role)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .user(let m): try m.encode(to: encoder)
        case .assistant(let m): try m.encode(to: encoder)
        }
    }
}
