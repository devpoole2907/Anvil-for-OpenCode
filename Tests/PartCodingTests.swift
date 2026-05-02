import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("Part Codable round-trips")
struct PartCodingTests {
    @Test func decodesTextPart() throws {
        let json = #"""
        {
          "type": "text",
          "id": "prt_1",
          "sessionID": "sess_1",
          "messageID": "msg_1",
          "text": "Hello, world!"
        }
        """#
        let part = try JSONDecoder().decode(Part.self, from: Data(json.utf8))
        guard case .text(let textPart) = part else {
            Issue.record("Expected text part")
            return
        }
        #expect(textPart.id == "prt_1")
        #expect(textPart.text == "Hello, world!")
    }

    @Test func decodesReasoningPart() throws {
        let json = #"""
        {
          "type": "reasoning",
          "id": "prt_2",
          "sessionID": "sess_1",
          "messageID": "msg_1",
          "text": "Let me think..."
        }
        """#
        let part = try JSONDecoder().decode(Part.self, from: Data(json.utf8))
        if case .reasoning(let reasoning) = part {
            #expect(reasoning.text == "Let me think...")
        } else {
            Issue.record("Expected reasoning part")
        }
    }

    @Test func decodesToolPartWithRunningState() throws {
        let json = #"""
        {
          "type": "tool",
          "id": "prt_3",
          "sessionID": "sess_1",
          "messageID": "msg_1",
          "tool": "bash",
          "state": { "status": "running", "input": { "command": "ls -la" } }
        }
        """#
        let part = try JSONDecoder().decode(Part.self, from: Data(json.utf8))
        guard case .tool(let toolPart) = part else {
            Issue.record("Expected tool part")
            return
        }
        #expect(toolPart.tool == "bash")
        #expect(toolPart.state.status == "running")
    }

    @Test func decodesToolPartWithCompletedState() throws {
        let json = #"""
        {
          "type": "tool",
          "id": "prt_4",
          "sessionID": "sess_1",
          "messageID": "msg_1",
          "tool": "read",
          "state": {
            "status": "completed",
            "input": { "path": "README.md" },
            "output": "# Project",
            "title": "Read README.md",
            "metadata": null
          }
        }
        """#
        let part = try JSONDecoder().decode(Part.self, from: Data(json.utf8))
        if case .tool(let toolPart) = part {
            #expect(toolPart.state.status == "completed")
            #expect(toolPart.state.output == "# Project")
        } else {
            Issue.record("Expected tool part")
        }
    }

    @Test func decodesUnknownTypeAsUnknown() throws {
        let json = #"""
        { "type": "weird-future-type", "id": "prt_x", "stuff": 42 }
        """#
        let part = try JSONDecoder().decode(Part.self, from: Data(json.utf8))
        if case .unknown(let type, let id, _) = part {
            #expect(type == "weird-future-type")
            #expect(id == "prt_x")
        } else {
            Issue.record("Expected unknown part")
        }
    }

    @Test func decodesStepPartWithStableID() throws {
        let json = #"""
        {
          "type": "step-start",
          "id": "prt_step",
          "sessionID": "sess_1",
          "messageID": "msg_1"
        }
        """#
        let part = try JSONDecoder().decode(Part.self, from: Data(json.utf8))
        if case .unknown(let type, let id, _) = part {
            #expect(type == "step-start")
            #expect(id == "prt_step")
        } else {
            Issue.record("Expected unknown step part")
        }
    }

    @Test func decodesUnknownToolState() throws {
        let json = #"""
        {
          "type": "tool",
          "id": "prt_future",
          "sessionID": "sess_1",
          "messageID": "msg_1",
          "tool": "bash",
          "state": {
            "status": "paused",
            "input": { "command": "pwd" }
          }
        }
        """#
        let part = try JSONDecoder().decode(Part.self, from: Data(json.utf8))
        guard case .tool(let toolPart) = part else {
            Issue.record("Expected tool part")
            return
        }
        #expect(toolPart.state.status == "paused")
        #expect(toolPart.state.input?.dictionaryValue?["command"] as? String == "pwd")
    }

    @Test func roundTripsTextPart() throws {
        let original = TextPart(
            id: "prt_1",
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "text",
            text: "Round trip",
            time: nil,
            synthetic: false
        )
        let data = try JSONEncoder().encode(Part.text(original))
        let decoded = try JSONDecoder().decode(Part.self, from: data)
        if case .text(let restored) = decoded {
            #expect(restored == original)
        } else {
            Issue.record("Round trip lost type")
        }
    }
}
