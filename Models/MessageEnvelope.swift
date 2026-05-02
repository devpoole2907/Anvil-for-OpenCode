import Foundation

/// Wire shape returned by `GET /session/{id}/message`: a message plus its parts.
struct MessageEnvelope: Codable, Hashable, Sendable {
    let info: Message
    let parts: [Part]
}
