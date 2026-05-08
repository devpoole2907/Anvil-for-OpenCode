import Testing
import Foundation

@testable import Anvil_for_OpenCode

/// Tests for `GroupedItem.id` — the PR changed `contextGroup` from a joined list of all part
/// IDs to using only the first part's ID (prefixed with "ctx-").
@Suite("GroupedItem")
struct GroupedItemTests {

    // MARK: - Helpers

    private func makePart(id: String, tool: String = "read") -> Part {
        let toolPart = ToolPart(
            id: id,
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "tool",
            tool: tool,
            state: .pending(ToolStatePending(status: "pending", input: nil)),
            callID: nil
        )
        return .tool(toolPart)
    }

    private func makeToolPart(id: String, tool: String = "read") -> ToolPart {
        ToolPart(
            id: id,
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "tool",
            tool: tool,
            state: .pending(ToolStatePending(status: "pending", input: nil)),
            callID: nil
        )
    }

    // MARK: - single case

    @Test func singleCaseIDMatchesPartID() {
        let part = makePart(id: "prt_abc")
        let item = GroupedItem.single(part)
        #expect(item.id == "prt_abc")
    }

    @Test func singleCaseIDIsPartIDNotPrefixed() {
        let part = makePart(id: "my_id")
        let item = GroupedItem.single(part)
        // Should NOT have "ctx-" prefix
        #expect(!item.id.hasPrefix("ctx-"))
    }

    // MARK: - contextGroup: post-PR uses first part's id

    @Test func contextGroupWithSinglePartUsesFirstPartID() {
        let tp = makeToolPart(id: "tool_111")
        let item = GroupedItem.contextGroup([tp])
        #expect(item.id == "ctx-tool_111")
    }

    @Test func contextGroupWithMultiplePartsUsesFirstPartIDOnly() {
        let tp1 = makeToolPart(id: "first_part")
        let tp2 = makeToolPart(id: "second_part")
        let tp3 = makeToolPart(id: "third_part")
        let item = GroupedItem.contextGroup([tp1, tp2, tp3])
        // Post-PR: only first part's id used
        #expect(item.id == "ctx-first_part")
    }

    @Test func contextGroupIDDoesNotContainSecondPartID() {
        let tp1 = makeToolPart(id: "alpha")
        let tp2 = makeToolPart(id: "beta")
        let item = GroupedItem.contextGroup([tp1, tp2])
        #expect(!item.id.contains("beta"))
    }

    @Test func contextGroupWithEmptyArrayUsesEmptyFallback() {
        let item = GroupedItem.contextGroup([])
        #expect(item.id == "ctx-empty")
    }

    @Test func contextGroupIDHasCtxPrefix() {
        let tp = makeToolPart(id: "xyz")
        let item = GroupedItem.contextGroup([tp])
        #expect(item.id.hasPrefix("ctx-"))
    }

    // MARK: - Stability: same parts produce same id (for SwiftUI ForEach)

    @Test func contextGroupIDIsStableForSameParts() {
        let tp1 = makeToolPart(id: "stable_id")
        let tp2 = makeToolPart(id: "other_id")
        let item1 = GroupedItem.contextGroup([tp1, tp2])
        let item2 = GroupedItem.contextGroup([tp1, tp2])
        #expect(item1.id == item2.id)
    }

    // MARK: - Regression: old behavior (joined all IDs) is no longer produced

    @Test func contextGroupIDDoesNotJoinAllPartIDs() {
        // Pre-PR: id was "ctx-part1-part2"; post-PR: id is "ctx-part1"
        let tp1 = makeToolPart(id: "part1")
        let tp2 = makeToolPart(id: "part2")
        let item = GroupedItem.contextGroup([tp1, tp2])
        // Verify old joined format is NOT produced
        #expect(item.id != "ctx-part1-part2")
        // Verify new format is produced
        #expect(item.id == "ctx-part1")
    }

    // MARK: - Different tool types in context group

    @Test func contextGroupCanContainMixedContextTools() {
        let glob = makeToolPart(id: "glob_1", tool: "glob")
        let grep = makeToolPart(id: "grep_2", tool: "grep")
        let list = makeToolPart(id: "list_3", tool: "list")
        let item = GroupedItem.contextGroup([glob, grep, list])
        #expect(item.id == "ctx-glob_1")
    }
}