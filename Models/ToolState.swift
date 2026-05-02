import Foundation

enum ToolState: Codable, Hashable, Sendable {
    case pending(ToolStatePending)
    case running(ToolStateRunning)
    case completed(ToolStateCompleted)
    case error(ToolStateError)
    case unknown(ToolStateUnknown)

    private enum CodingKeys: String, CodingKey { case status }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(String.self, forKey: .status)
        switch status {
        case "pending":
            self = .pending(try ToolStatePending(from: decoder))
        case "running":
            self = .running(try ToolStateRunning(from: decoder))
        case "completed":
            self = .completed(try ToolStateCompleted(from: decoder))
        case "error":
            self = .error(try ToolStateError(from: decoder))
        default:
            self = .unknown(ToolStateUnknown(status: status, raw: try AnyCodable(from: decoder)))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .pending(let s): try s.encode(to: encoder)
        case .running(let s): try s.encode(to: encoder)
        case .completed(let s): try s.encode(to: encoder)
        case .error(let s): try s.encode(to: encoder)
        case .unknown(let s): try s.encode(to: encoder)
        }
    }

    var status: String {
        switch self {
        case .pending: "pending"
        case .running: "running"
        case .completed: "completed"
        case .error: "error"
        case .unknown(let s): s.status
        }
    }

    var input: AnyCodable? {
        switch self {
        case .pending: nil
        case .running(let s): s.input
        case .completed(let s): s.input
        case .error(let s): s.input
        case .unknown(let s): s.raw.dictionaryValue?["input"].map(AnyCodable.init)
        }
    }

    var output: String? {
        if case .completed(let s) = self { return s.output }
        return nil
    }

    var title: String? {
        if case .completed(let s) = self { return s.title }
        return nil
    }

    var metadata: AnyCodable? {
        if case .completed(let s) = self { return s.metadata }
        return nil
    }

    var time: ToolTime? {
        switch self {
        case .pending: nil
        case .running(let s): s.time
        case .completed(let s): s.time
        case .error(let s): s.time
        case .unknown: nil
        }
    }

    var errorMessage: String? {
        if case .error(let s) = self { return s.error }
        return nil
    }
}

struct ToolStatePending: Codable, Hashable, Sendable {
    let status: String
}

struct ToolStateRunning: Codable, Hashable, Sendable {
    let status: String
    var input: AnyCodable?
    var time: ToolTime?
}

struct ToolStateCompleted: Codable, Hashable, Sendable {
    let status: String
    let input: AnyCodable?
    let output: String?
    let title: String?
    let metadata: AnyCodable?
    let time: ToolTime?
}

struct ToolStateError: Codable, Hashable, Sendable {
    let status: String
    let error: String
    let input: AnyCodable?
    let time: ToolTime?
}

struct ToolStateUnknown: Codable, Hashable, Sendable {
    let status: String
    let raw: AnyCodable

    private enum CodingKeys: String, CodingKey { case status }

    init(status: String, raw: AnyCodable) {
        self.status = status
        self.raw = raw
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(String.self, forKey: .status)
        self.raw = try AnyCodable(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try raw.encode(to: encoder)
    }
}
