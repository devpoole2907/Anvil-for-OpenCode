import Foundation

/// Client-side grouping. Not from the server.
/// One user message + the assistant message(s) that responded to it,
/// along with their respective parts in order.
struct Turn: Identifiable, Hashable, Sendable {
    let userMessage: UserMessage
    let assistantMessages: [AssistantMessage]
    let userParts: [Part]
    let assistantParts: [Part]

    var id: String { userMessage.id }
}
