import Foundation
import Observation

@MainActor
@Observable
final class ChatStore {
    let sessionID: String

    var messages: [Message] = []
    var parts: [String: [Part]] = [:]
    var working: Bool = false
    var loading: Bool = false
    var lastError: OpencodeError?

    /// Buffer for deltas that arrive before the corresponding `message.part.updated`.
    private var pendingDeltas: [String: String] = [:]

    private let client: OpencodeClient

    init(client: OpencodeClient, sessionID: String) {
        self.client = client
        self.sessionID = sessionID
    }

    // MARK: - Loading

    func load(directory: String) async {
        loading = true
        defer { loading = false }
        do {
            let envelopes = try await client.messages(sessionID: sessionID, directory: directory)
            messages = envelopes.map(\.info).sorted { $0.time.created < $1.time.created }
            var nextParts: [String: [Part]] = [:]
            for envelope in envelopes {
                nextParts[envelope.info.id] = envelope.parts
            }
            parts = nextParts
            recomputeWorking()
        } catch {
            lastError = OpencodeError(error)
        }
    }

    // MARK: - Sending

    func send(text: String, directory: String, model: ModelRef?) async {
        let body = PromptBody(parts: [.text(text)], model: model)
        working = true
        do {
            try await client.sendPrompt(sessionID: sessionID, directory: directory, body: body)
        } catch {
            lastError = OpencodeError(error)
            working = false
        }
    }

    func interrupt(directory: String) async {
        do {
            try await client.interrupt(sessionID: sessionID, directory: directory)
        } catch {
            lastError = OpencodeError(error)
        }
    }

    // MARK: - Event application

    func apply(_ event: ServerEvent) {
        switch event {
        case .messageUpdated(let message) where message.sessionID == sessionID:
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = message
            } else {
                messages.append(message)
            }
            messages.sort { $0.time.created < $1.time.created }
            recomputeWorking()

        case .messageRemoved(let sid, let mid) where sid == sessionID:
            messages.removeAll { $0.id == mid }
            parts.removeValue(forKey: mid)
            recomputeWorking()

        case .messagePartUpdated(let part) where part.sessionID == sessionID:
            insertOrReplace(part: part)
            drainPendingDelta(for: part.id)

        case .messagePartDelta(let delta) where delta.sessionID == sessionID:
            applyDelta(delta)

        case .messagePartRemoved(let sid, let mid, let pid) where sid == sessionID:
            parts[mid]?.removeAll { $0.id == pid }

        default:
            break
        }
    }

    // MARK: - Derived

    var turns: [Turn] {
        var result: [Turn] = []
        var i = 0
        while i < messages.count {
            guard case .user(let userMessage) = messages[i] else {
                i += 1
                continue
            }
            var assistantMessages: [AssistantMessage] = []
            var assistantParts: [Part] = []
            var j = i + 1
            while j < messages.count, case .assistant(let am) = messages[j], am.parentID == userMessage.id {
                assistantMessages.append(am)
                assistantParts.append(contentsOf: parts[am.id] ?? [])
                j += 1
            }
            let userParts = (parts[userMessage.id] ?? [])
                .filter { part in
                    if case .text(let t) = part, t.isSynthetic { return false }
                    return true
                }
            result.append(Turn(
                userMessage: userMessage,
                assistantMessages: assistantMessages,
                userParts: userParts,
                assistantParts: assistantParts
            ))
            i = j
        }
        return result
    }

    // MARK: - Helpers

    private func insertOrReplace(part: Part) {
        var bucket = parts[part.messageID] ?? []
        if let index = bucket.firstIndex(where: { $0.id == part.id }) {
            bucket[index] = part
        } else {
            bucket.append(part)
        }
        parts[part.messageID] = bucket
    }

    private func applyDelta(_ delta: MessagePartDelta) {
        guard var bucket = parts[delta.messageID],
              let index = bucket.firstIndex(where: { $0.id == delta.partID })
        else {
            // Buffer until the corresponding part lands.
            pendingDeltas[delta.partID, default: ""] += delta.delta
            return
        }
        var part = bucket[index]
        DeltaApplier.apply(delta: delta, to: &part)
        bucket[index] = part
        parts[delta.messageID] = bucket
    }

    private func drainPendingDelta(for partID: String) {
        guard let buffered = pendingDeltas.removeValue(forKey: partID) else { return }
        guard let messageID = parts.first(where: { $0.value.contains { $0.id == partID } })?.key,
              var bucket = parts[messageID],
              let index = bucket.firstIndex(where: { $0.id == partID })
        else { return }
        let synthetic = MessagePartDelta(
            sessionID: sessionID,
            messageID: messageID,
            partID: partID,
            field: "text",
            delta: buffered
        )
        var part = bucket[index]
        DeltaApplier.apply(delta: synthetic, to: &part)
        bucket[index] = part
        parts[messageID] = bucket
    }

    private func recomputeWorking() {
        // Working when the most recent assistant message has no completion timestamp.
        if case .assistant(let last) = messages.last {
            working = last.time.completed == nil
        } else {
            working = false
        }
    }
}
