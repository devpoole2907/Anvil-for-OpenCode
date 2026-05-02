import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ChatStore {
    let sessionID: String

    var messages: [Message] = []
    var parts: [String: [Part]] = [:]
    var working: Bool = false
    var loading: Bool = false
    var lastError: OpencodeError?

    /// True once the user has sent at least one message in this store instance.
    /// Prevents session.status "busy" events from falsely setting working=true on fresh sessions.
    private var hasEverSent: Bool = false

    /// Buffer for deltas that arrive before the corresponding `message.part.updated`.
    private var pendingDeltas: [String: String] = [:]
    private var sendResyncTask: Task<Void, Never>?
    private var eventResyncTask: Task<Void, Never>?
    private var activeDirectory: String?

    private let client: OpencodeClient

    init(client: OpencodeClient, sessionID: String) {
        self.client = client
        self.sessionID = sessionID
    }

    // MARK: - Loading

    func load(directory: String) async {
        print("[ChatStore:\(sessionID.prefix(8))] load() start")
        activeDirectory = directory
        loading = true
        defer {
            withAnimation {
                loading = false
            }
        }
        do {
            try await syncMessages(directory: directory)
            // Don't infer working from message state on load — session.status events are authoritative.
            print("[ChatStore:\(sessionID.prefix(8))] load() complete: \(messages.count) messages")
        } catch {
            print("[ChatStore:\(sessionID.prefix(8))] load() error: \(error)")
            lastError = OpencodeError(error)
        }
    }

    // MARK: - Sending

    func send(text: String, directory: String, model: ModelRef?, mode: PromptMode?, effort: PromptEffort?) async {
        activeDirectory = directory
        let body = PromptBody(parts: [.text(text)], model: model, mode: mode?.rawValue, effort: effort?.rawValue)
        let baselineMessageCount = messages.count
        withAnimation {
            working = true
        }
        print("[ChatStore:\(sessionID.prefix(8))] send() called, working=true")
        do {
            try await client.sendPrompt(sessionID: sessionID, directory: directory, body: body)
            hasEverSent = true
            print("[ChatStore:\(sessionID.prefix(8))] send() prompt submitted OK")
            startSendResyncLoop(directory: directory, baselineMessageCount: baselineMessageCount)
        } catch {
            print("[ChatStore:\(sessionID.prefix(8))] send() error: \(error)")
            lastError = OpencodeError(error)
            withAnimation {
                working = false
            }
        }
    }

    func interrupt(directory: String) async {
        sendResyncTask?.cancel()
        withAnimation {
            working = false
        }
        do {
            try await client.interrupt(sessionID: sessionID, directory: directory)
        } catch {
            lastError = OpencodeError(error)
        }
    }

    // MARK: - Event application

    func apply(_ event: ServerEvent) {
        withAnimation(.spring(duration: 0.3)) {
            switch event {
            case .sessionStatus(let sid, let status) where sid == sessionID:
                // Only apply "busy" if we've sent a message or already have messages; prevents
                // false working state when a new empty session receives a stale "busy" event.
                let shouldBeBusy = status == "busy" && (hasEverSent || !messages.isEmpty)
                print("[ChatStore:\(sessionID.prefix(8))] session.status=\(status) hasEverSent=\(hasEverSent) messages=\(messages.count) → working=\(shouldBeBusy)")
                working = shouldBeBusy
                if !shouldBeBusy {
                    sendResyncTask?.cancel()
                }

            case .messageUpdated(let message) where message.sessionID == sessionID:
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index] = message
                } else {
                    messages.append(message)
                }
                messages.sort { $0.time.created < $1.time.created }
                scheduleEventResync()

            case .messageRemoved(let sid, let mid) where sid == sessionID:
                messages.removeAll { $0.id == mid }
                parts.removeValue(forKey: mid)

            case .messagePartUpdated(let part, let delta) where part.sessionID == sessionID:
                insertOrReplace(part: part)
                drainPendingDelta(for: part.id)
                if delta == nil || !messages.contains(where: { $0.id == part.messageID }) {
                    scheduleEventResync()
                }

            case .messagePartDelta(let delta) where delta.sessionID == sessionID:
                applyDelta(delta)

            case .messagePartRemoved(let sid, let mid, let pid) where sid == sessionID:
                parts[mid]?.removeAll { $0.id == pid }

            default:
                break
            }
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
            let userParts = parts[userMessage.id] ?? []
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

    private func syncMessages(directory: String) async throws {
        let envelopes = try await client.messages(sessionID: sessionID, directory: directory)
        messages = envelopes.map(\.info).sorted { $0.time.created < $1.time.created }
        var nextParts: [String: [Part]] = [:]
        for envelope in envelopes {
            nextParts[envelope.info.id] = envelope.parts
        }
        parts = nextParts
        // Remove buffered deltas for parts that now exist in the snapshot to avoid re-applying stale deltas
        let allPartIDs = Set(nextParts.values.flatMap { $0.map(\.id) })
        for partID in allPartIDs {
            pendingDeltas.removeValue(forKey: partID)
        }
    }

    private func startSendResyncLoop(directory: String, baselineMessageCount: Int) {
        sendResyncTask?.cancel()
        sendResyncTask = Task { [weak self] in
            guard let self else { return }
            for attempt in 0..<600 {
                guard !Task.isCancelled else { return }
                do {
                    try await self.syncMessages(directory: directory)
                    if self.isPromptComplete(baselineMessageCount: baselineMessageCount) {
                        self.working = false
                        return
                    }
                    self.working = true
                } catch {
                    self.lastError = OpencodeError(error)
                }
                let delay = attempt < 20 ? 500 : 1_000
                try? await Task.sleep(for: .milliseconds(delay))
            }
            self.working = false
        }
    }

    private func scheduleEventResync() {
        guard let activeDirectory else { return }
        eventResyncTask?.cancel()
        eventResyncTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            do {
                try await self.syncMessages(directory: activeDirectory)
            } catch {
                self.lastError = OpencodeError(error)
            }
        }
    }

    private func isPromptComplete(baselineMessageCount: Int) -> Bool {
        guard messages.count > baselineMessageCount else { return false }
        guard case .assistant(let assistant) = messages.last else { return false }
        return assistant.time.completed != nil || assistant.error != nil
    }

}
