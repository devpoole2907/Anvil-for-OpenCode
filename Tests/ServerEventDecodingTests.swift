import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("ServerEvent decoding")
struct ServerEventDecodingTests {
    @Test func decodesServerConnected() throws {
        let json = #"""
        { "payload": { "type": "server.connected", "properties": {} } }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .serverConnected = event {} else {
            Issue.record("Expected serverConnected")
        }
    }

    @Test func decodesMessagePartDelta() throws {
        let json = #"""
        {
          "payload": {
            "type": "message.part.delta",
            "properties": {
              "sessionID": "sess_x",
              "messageID": "msg_y",
              "partID": "prt_z",
              "field": "text",
              "delta": "Hello "
            }
          }
        }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .messagePartDelta(let delta) = event {
            #expect(delta.partID == "prt_z")
            #expect(delta.delta == "Hello ")
        } else {
            Issue.record("Expected messagePartDelta")
        }
    }

    @Test func decodesTopLevelMessagePartDelta() throws {
        let json = #"""
        {
          "type": "message.part.delta",
          "properties": {
            "sessionID": "sess_x",
            "messageID": "msg_y",
            "partID": "prt_z",
            "field": "text",
            "delta": "Hello "
          }
        }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .messagePartDelta(let delta) = event {
            #expect(delta.sessionID == "sess_x")
            #expect(delta.messageID == "msg_y")
            #expect(delta.partID == "prt_z")
            #expect(delta.delta == "Hello ")
        } else {
            Issue.record("Expected messagePartDelta")
        }
    }

    @Test func decodesTopLevelMessagePartUpdatedWithDelta() throws {
        let json = #"""
        {
          "type": "message.part.updated",
          "properties": {
            "part": {
              "type": "text",
              "id": "prt_z",
              "sessionID": "sess_x",
              "messageID": "msg_y",
              "text": "Hello"
            },
            "delta": "lo"
          }
        }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .messagePartUpdated(part: let part, delta: let delta) = event {
            #expect(part.id == "prt_z")
            #expect(delta == "lo")
        } else {
            Issue.record("Expected messagePartUpdated")
        }
    }

    @Test func decodesTopLevelSessionStatusWithStringStatus() throws {
        let json = #"""
        {
          "type": "session.status",
          "properties": {
            "sessionID": "sess_x",
            "status": "idle"
          }
        }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .sessionStatus(let sessionID, let status) = event {
            #expect(sessionID == "sess_x")
            #expect(status == "idle")
        } else {
            Issue.record("Expected sessionStatus")
        }
    }

    @Test func decodesSessionIdleAsIdleStatus() throws {
        let json = #"""
        {
          "type": "session.idle",
          "properties": {
            "sessionID": "sess_x"
          }
        }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .sessionStatus(let sessionID, let status) = event {
            #expect(sessionID == "sess_x")
            #expect(status == "idle")
        } else {
            Issue.record("Expected sessionStatus")
        }
    }

    @Test func decodesUnknownTypeAsIgnored() throws {
        let json = #"""
        { "payload": { "type": "future.event", "properties": {} } }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .ignored(let type) = event {
            #expect(type == "future.event")
        } else {
            Issue.record("Expected ignored")
        }
    }

    @Test func decodesPermissionUpdated() throws {
        let json = #"""
        {
          "payload": {
            "type": "permission.updated",
            "properties": {
              "info": {
                "id": "perm_1",
                "sessionID": "sess_1",
                "messageID": null,
                "callID": null,
                "type": "bash",
                "pattern": "rm *",
                "metadata": null,
                "time": { "created": 1700000000000 }
              }
            }
          }
        }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .permissionUpdated(let permission) = event {
            #expect(permission.id == "perm_1")
            #expect(permission.pattern == "rm *")
        } else {
            Issue.record("Expected permissionUpdated")
        }
    }

    @Test func decodesSessionDeleted() throws {
        let json = #"""
        { "payload": { "type": "session.deleted", "properties": { "sessionID": "sess_gone" } } }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .sessionDeleted(let id) = event {
            #expect(id == "sess_gone")
        } else {
            Issue.record("Expected sessionDeleted")
        }
    }

    @Test func decodesSyncAsIgnored() throws {
        let json = #"""
        {
          "payload": {
            "type": "sync"
          },
          "directory": "/foo",
          "project": "abc"
        }
        """#
        let envelope = try JSONDecoder().decode(SSEEnvelope.self, from: Data(json.utf8))
        let event = ServerEvent(from: envelope)
        if case .ignored(let type) = event {
            #expect(type == "sync")
        } else {
            Issue.record("Expected sync to be ignored")
        }
    }
}
