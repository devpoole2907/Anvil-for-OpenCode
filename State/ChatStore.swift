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
    private var workingResyncTask: Task<Void, Never>?
    private var eventResyncTask: Task<Void, Never>?
    private var activeDirectory: String?

    private let client: OpencodeClient
    private let setSessionBusy: @MainActor @Sendable (String, Bool) -> Void

    init(
        client: OpencodeClient,
        sessionID: String,
        setSessionBusy: @escaping @MainActor @Sendable (String, Bool) -> Void
    ) {
        self.client = client
        self.sessionID = sessionID
        self.setSessionBusy = setSessionBusy
    }

    // MARK: - Loading

    func load(directory: String) async {
        print("[ChatStore:\(sessionID.prefix(8))] load() start")
        sendResyncTask?.cancel()
        sendResyncTask = nil
        workingResyncTask?.cancel()
        workingResyncTask = nil
        eventResyncTask?.cancel()
        eventResyncTask = nil
        activeDirectory = directory
        loading = true
        defer {
            withAnimation {
                loading = false
            }
        }
        do {
            try await syncMessages(directory: directory)
            hasEverSent = messages.contains {
                if case .user = $0 { return true }
                return false
            }
            let inferredWorking = inferredWorkingState
            withAnimation {
                working = inferredWorking
            }
            setSessionBusy(sessionID, inferredWorking)
            if inferredWorking {
                startWorkingResyncLoop(directory: directory)
            }
            print("[ChatStore:\(sessionID.prefix(8))] load() complete: \(messages.count) messages")
            print("[ChatStore:\(sessionID.prefix(8))] load() inferred working=\(inferredWorking)")
        } catch {
            print("[ChatStore:\(sessionID.prefix(8))] load() error: \(error)")
            lastError = OpencodeError(error)
        }
    }

    // MARK: - Sending

    func send(
        text: String,
        attachments: [PendingAttachment],
        directory: String,
        model: ModelRef?,
        mode: PromptMode?,
        effort: PromptEffort?
    ) async {
        sendResyncTask?.cancel()
        sendResyncTask = nil
        workingResyncTask?.cancel()
        workingResyncTask = nil
        eventResyncTask?.cancel()
        eventResyncTask = nil
        activeDirectory = directory
        var promptParts = attachments.map(\.promptPart)
        if !text.isEmpty {
            promptParts.append(.text(text))
        }
        let body = PromptBody(parts: promptParts, model: model, mode: mode?.rawValue, effort: effort?.rawValue)
        let baselineMessageCount = messages.count
        withAnimation {
            working = true
        }
        setSessionBusy(sessionID, true)
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
            setSessionBusy(sessionID, false)
        }
    }

    func interrupt(directory: String) async {
        sendResyncTask?.cancel()
        sendResyncTask = nil
        withAnimation {
            working = false
        }
        setSessionBusy(sessionID, false)
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
                setSessionBusy(sessionID, shouldBeBusy)
                if shouldBeBusy, let activeDirectory {
                    startWorkingResyncLoop(directory: activeDirectory)
                } else {
                    sendResyncTask?.cancel()
                    sendResyncTask = nil
                    workingResyncTask?.cancel()
                    workingResyncTask = nil
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
                print("[ChatStore:\(sessionID.prefix(8))] part.updated \(part.id.prefix(8)) textLen=\(part.textLength) delta=\(delta?.count ?? 0)")
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
            print("[ChatStore:\(sessionID.prefix(8))] delta buffered \(delta.partID.prefix(8))")
            pendingDeltas[delta.partID, default: ""] += delta.delta
            return
        }
        var part = bucket[index]
        DeltaApplier.apply(delta: delta, to: &part)
        bucket[index] = part
        parts[delta.messageID] = bucket
        print("[ChatStore:\(sessionID.prefix(8))] delta +\(delta.delta.count)=\(part.textLength)")
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
        // Merge server parts with locally accumulated (streamed) parts
        // to preserve text built up via SSE deltas during streaming.
        var nextParts: [String: [Part]] = [:]
        for envelope in envelopes {
            nextParts[envelope.info.id] = envelope.parts
        }
        for (messageID, serverParts) in nextParts {
            guard var localParts = parts[messageID], !localParts.isEmpty else {
                parts[messageID] = serverParts
                continue
            }
            for serverPart in serverParts {
                if let index = localParts.firstIndex(where: { $0.id == serverPart.id }) {
                    // Prefer whichever has more text (local wins during SSE streaming)
                    if serverPart.textLength > localParts[index].textLength {
                        localParts[index] = serverPart
                    }
                } else {
                    localParts.append(serverPart)
                }
            }
            // Remove local parts no longer on the server
            let serverIDs = Set(serverParts.map(\.id))
            localParts.removeAll { !serverIDs.contains($0.id) }
            parts[messageID] = localParts
        }
        // Remove buffered deltas for parts that now exist in the snapshot to avoid re-applying stale deltas
        let allPartIDs = Set(nextParts.values.flatMap { $0.map(\.id) })
        for partID in allPartIDs {
            pendingDeltas.removeValue(forKey: partID)
        }
    }

    private var inferredWorkingState: Bool {
        guard !messages.isEmpty else { return false }
        guard case .assistant(let assistant) = messages.last else { return false }
        return assistant.time.completed == nil && assistant.error == nil
    }

    private func startSendResyncLoop(directory: String, baselineMessageCount: Int) {
        sendResyncTask?.cancel()
        sendResyncTask = nil
        workingResyncTask?.cancel()
        workingResyncTask = nil
        sendResyncTask = Task { [weak self] in
            guard let self else { return }
            let capturedDirectory = directory
            for attempt in 0..<600 {
                guard !Task.isCancelled else { return }
                guard self.activeDirectory == capturedDirectory else { return }
                do {
                    try await self.syncMessages(directory: directory)
                    guard self.activeDirectory == capturedDirectory else { return }
                    if self.isPromptComplete(baselineMessageCount: baselineMessageCount) {
                        self.working = false
                        self.setSessionBusy(self.sessionID, false)
                        return
                    }
                    self.working = true
                    self.setSessionBusy(self.sessionID, true)
                } catch {
                    self.lastError = OpencodeError(error)
                }
                let delay = attempt < 30 ? 150 : 500
                try? await Task.sleep(for: .milliseconds(delay))
            }
            self.working = false
            self.setSessionBusy(self.sessionID, false)
        }
    }

    private func startWorkingResyncLoop(directory: String) {
        guard workingResyncTask == nil else { return }
        workingResyncTask = Task { [weak self] in
            guard let self else { return }
            let capturedDirectory = directory
            defer { self.workingResyncTask = nil }
            for _ in 0..<600 {
                guard !Task.isCancelled else { return }
                guard self.activeDirectory == capturedDirectory else { return }
                do {
                    try await self.syncMessages(directory: capturedDirectory)
                    guard self.activeDirectory == capturedDirectory else { return }
                    let inferredWorking = self.inferredWorkingState
                    await MainActor.run {
                        self.working = inferredWorking
                        self.setSessionBusy(self.sessionID, inferredWorking)
                    }
                    if !inferredWorking {
                        return
                    }
                } catch {
                    self.lastError = OpencodeError(error)
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
            await MainActor.run {
                self.working = false
                self.setSessionBusy(self.sessionID, false)
            }
        }
    }

    private func scheduleEventResync() {
        guard let activeDirectory else { return }
        eventResyncTask?.cancel()
        eventResyncTask = nil
        eventResyncTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let capturedDirectory = activeDirectory
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            guard self.activeDirectory == capturedDirectory else { return }
            do {
                try await self.syncMessages(directory: capturedDirectory)
                guard self.activeDirectory == capturedDirectory else { return }
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
