import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("DeltaApplier")
struct DeltaApplierTests {
    @Test func appendsTextDeltaToTextPart() {
        var part: Part = .text(TextPart(
            id: "prt_1",
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "text",
            text: "Hello",
            time: nil,
            synthetic: nil
        ))
        let delta = MessagePartDelta(
            sessionID: "sess_1",
            messageID: "msg_1",
            partID: "prt_1",
            field: "text",
            delta: ", world!"
        )
        DeltaApplier.apply(delta: delta, to: &part)
        if case .text(let textPart) = part {
            #expect(textPart.text == "Hello, world!")
        } else {
            Issue.record("Expected text part after delta")
        }
    }

    @Test func appendsTextDeltaToReasoningPart() {
        var part: Part = .reasoning(ReasoningPart(
            id: "prt_2",
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "reasoning",
            text: "I need to ",
            time: nil
        ))
        let delta = MessagePartDelta(
            sessionID: "sess_1",
            messageID: "msg_1",
            partID: "prt_2",
            field: "text",
            delta: "consider..."
        )
        DeltaApplier.apply(delta: delta, to: &part)
        if case .reasoning(let reasoning) = part {
            #expect(reasoning.text == "I need to consider...")
        } else {
            Issue.record("Expected reasoning part after delta")
        }
    }

    @Test func ignoresDeltaOnUnknownField() {
        var part: Part = .text(TextPart(
            id: "prt_1",
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "text",
            text: "Hello",
            time: nil,
            synthetic: nil
        ))
        let delta = MessagePartDelta(
            sessionID: "sess_1",
            messageID: "msg_1",
            partID: "prt_1",
            field: "weirdField",
            delta: "ignored"
        )
        DeltaApplier.apply(delta: delta, to: &part)
        if case .text(let textPart) = part {
            #expect(textPart.text == "Hello")
        } else {
            Issue.record("Part type changed unexpectedly")
        }
    }

    @Test func ignoresDeltaOnNonTextPart() {
        var part: Part = .compaction(CompactionPart(
            id: "prt_3",
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "compaction",
            time: nil
        ))
        let delta = MessagePartDelta(
            sessionID: "sess_1",
            messageID: "msg_1",
            partID: "prt_3",
            field: "text",
            delta: "won't apply"
        )
        DeltaApplier.apply(delta: delta, to: &part)
        if case .compaction = part {
            // Expected: part unchanged
        } else {
            Issue.record("Compaction part should be unchanged")
        }
    }
}
