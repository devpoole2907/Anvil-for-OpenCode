import Foundation

// MARK: - SSE wrapper (outer envelope)

/// The outer JSON the server sends on each SSE `data:` line.
/// Decoded first, then `ServerEvent` is extracted from `payload`.
struct SSEEnvelope: Decodable, Sendable {
    struct Payload: Decodable {
        let type: String
        let properties: AnyCodable?
    }

    let payload: Payload

    private enum CodingKeys: String, CodingKey {
        case payload
        case type
        case properties
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let payload = try container.decodeIfPresent(Payload.self, forKey: .payload) {
            self.payload = payload
        } else {
            self.payload = try Payload(from: decoder)
        }
    }
}

// MARK: - ServerEvent

enum ServerEvent: Sendable {
    case sessionUpdated(Session)
    case sessionDeleted(sessionID: String)
    case messageUpdated(Message)
    case messageRemoved(sessionID: String, messageID: String)
    case messagePartUpdated(part: Part, delta: String?)
    case messagePartDelta(MessagePartDelta)
    case messagePartRemoved(sessionID: String, messageID: String, partID: String)
    case permissionUpdated(Permission)
    case permissionReplied(permissionID: String)
    case serverConnected
    case sessionStatus(sessionID: String, status: String) // "busy" or "idle"
    case ignored(type: String)

    init(from envelope: SSEEnvelope) {
        let type = envelope.payload.type
        switch type {
        case "server.connected":
            self = .serverConnected
        case "session.updated":
            if let props = envelope.payload.properties,
               let info: Session = props.decoded(SessionUpdatedPayload.self)?.info {
                self = .sessionUpdated(info)
            } else {
                self = .ignored(type: type)
            }
        case "session.deleted":
            if let props = envelope.payload.properties,
               let payload = props.decoded(SessionDeletedPayload.self) {
                self = .sessionDeleted(sessionID: payload.sessionID)
            } else if let props = envelope.payload.properties,
                      let info: Session = props.decoded(SessionUpdatedPayload.self)?.info {
                self = .sessionDeleted(sessionID: info.id)
            } else {
                self = .ignored(type: type)
            }
        case "message.updated":
            if let props = envelope.payload.properties,
               let info: Message = props.decoded(MessageUpdatedPayload.self)?.info {
                self = .messageUpdated(info)
            } else {
                self = .ignored(type: type)
            }
        case "message.removed":
            if let props = envelope.payload.properties,
               let payload: MessageRemovedPayload = props.decoded(MessageRemovedPayload.self) {
                self = .messageRemoved(sessionID: payload.sessionID, messageID: payload.messageID)
            } else {
                self = .ignored(type: type)
            }
        case "message.part.updated":
            if let props = envelope.payload.properties,
               let payload = props.decoded(MessagePartUpdatedPayload.self) {
                self = .messagePartUpdated(part: payload.part, delta: payload.delta)
            } else {
                self = .ignored(type: type)
            }
        case "message.part.delta":
            if let props = envelope.payload.properties,
               let delta: MessagePartDelta = props.decoded(MessagePartDelta.self) {
                self = .messagePartDelta(delta)
            } else {
                self = .ignored(type: type)
            }
        case "message.part.removed":
            if let props = envelope.payload.properties,
               let payload: MessagePartRemovedPayload = props.decoded(MessagePartRemovedPayload.self) {
                self = .messagePartRemoved(
                    sessionID: payload.sessionID,
                    messageID: payload.messageID,
                    partID: payload.partID
                )
            } else {
                self = .ignored(type: type)
            }
        case "permission.updated":
            if let props = envelope.payload.properties,
               let info: Permission = props.decoded(PermissionUpdatedPayload.self)?.info {
                self = .permissionUpdated(info)
            } else if let props = envelope.payload.properties,
                      let permission: Permission = props.decoded(Permission.self) {
                self = .permissionUpdated(permission)
            } else {
                self = .ignored(type: type)
            }
        case "permission.replied":
            if let props = envelope.payload.properties,
               let payload: PermissionRepliedPayload = props.decoded(PermissionRepliedPayload.self) {
                self = .permissionReplied(permissionID: payload.permissionID)
            } else {
                self = .ignored(type: type)
            }
        case "sync":
            self = .ignored(type: type)
        case "session.status":
            if let props = envelope.payload.properties,
               let payload: SessionStatusPayload = props.decoded(SessionStatusPayload.self) {
                self = .sessionStatus(sessionID: payload.sessionID, status: payload.status.type)
            } else {
                self = .ignored(type: type)
            }
        case "session.idle":
            if let props = envelope.payload.properties,
               let payload: SessionIdlePayload = props.decoded(SessionIdlePayload.self) {
                self = .sessionStatus(sessionID: payload.sessionID, status: "idle")
            } else {
                self = .ignored(type: type)
            }
        case "session.diff":
            // NOTE: session.diff is emitted on every update; ignore for v1, UI re-fetches messages.
            self = .ignored(type: type)
        default:
            self = .ignored(type: type)
        }
    }
}

// MARK: - MessagePartDelta

struct MessagePartDelta: Decodable, Sendable {
    let sessionID: String
    let messageID: String
    let partID: String
    let field: String
    let delta: String
}

// MARK: - Payload structs

struct SessionUpdatedPayload: Decodable {
    let info: Session
}

struct SessionDeletedPayload: Decodable {
    let sessionID: String
}

struct MessageUpdatedPayload: Decodable {
    let info: Message
}

struct MessageRemovedPayload: Decodable {
    let sessionID: String
    let messageID: String
}

struct MessagePartUpdatedPayload: Decodable {
    let part: Part
    let delta: String?
}

struct MessagePartRemovedPayload: Decodable {
    let sessionID: String
    let messageID: String
    let partID: String
}

struct PermissionUpdatedPayload: Decodable {
    let info: Permission
}

struct PermissionRepliedPayload: Decodable {
    let permissionID: String
}

struct SessionStatusPayload: Decodable {
    let sessionID: String
    let status: StatusPayload
    struct StatusPayload: Decodable {
        let type: String

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let type = try? container.decode(String.self) {
                self.type = type
            } else {
                let keyed = try decoder.container(keyedBy: CodingKeys.self)
                self.type = try keyed.decode(String.self, forKey: .type)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case type
        }
    }
}

struct SessionIdlePayload: Decodable {
    let sessionID: String
}
