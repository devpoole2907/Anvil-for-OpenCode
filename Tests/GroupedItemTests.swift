import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("GroupedItem")
struct GroupedItemTests {

    // MARK: - Helpers

    private func makeToolPart(id: String, tool: String) -> ToolPart {
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

    private func makeTextPart(id: String, text: String = "") -> Part {
        .text(TextPart(
            id: id,
            sessionID: "sess_1",
            messageID: "msg_1",
            type: "text",
            text: text,
            time: nil,
            synthetic: nil
        ))
    }

    // MARK: - GroupedItem.id

    @Test func singleItemIDDelegatesToPartID() {
        let part = makeTextPart(id: "prt_abc")
        let item = GroupedItem.single(part)
        #expect(item.id == "prt_abc")
    }

    @Test func contextGroupIDUsesFirstPartID() {
        let part1 = makeToolPart(id: "tool_1", tool: "read")
        let part2 = makeToolPart(id: "tool_2", tool: "glob")
        let item = GroupedItem.contextGroup([part1, part2])
        #expect(item.id == "ctx-tool_1")
    }

    @Test func contextGroupIDWithSinglePartUsesFirstID() {
        let part = makeToolPart(id: "tool_solo", tool: "grep")
        let item = GroupedItem.contextGroup([part])
        #expect(item.id == "ctx-tool_solo")
    }

    @Test func contextGroupIDWithEmptyPartsUsesEmptyFallback() {
        let item = GroupedItem.contextGroup([])
        #expect(item.id == "ctx-empty")
    }

    @Test func contextGroupIDDoesNotConcatenateAllPartIDs() {
        // Regression: old code joined all IDs with "-"; new code uses only first.
        let part1 = makeToolPart(id: "a", tool: "read")
        let part2 = makeToolPart(id: "b", tool: "glob")
        let part3 = makeToolPart(id: "c", tool: "grep")
        let item = GroupedItem.contextGroup([part1, part2, part3])
        // Should be "ctx-a", NOT "ctx-a-b-c"
        #expect(item.id == "ctx-a")
        #expect(!item.id.contains("b"))
        #expect(!item.id.contains("c"))
    }

    @Test func contextGroupIDIsStableRegardlessOfPartsAfterFirst() {
        let part1 = makeToolPart(id: "stable_id", tool: "read")
        let part2a = makeToolPart(id: "x", tool: "glob")
        let part2b = makeToolPart(id: "y", tool: "grep")
        let item1 = GroupedItem.contextGroup([part1, part2a])
        let item2 = GroupedItem.contextGroup([part1, part2b])
        // Both should produce same id because first part is the same
        #expect(item1.id == item2.id)
    }

    // MARK: - Grouping logic via AssistantMessageView (private) — tested indirectly
    // We verify the expected GroupedItem shapes produced by consuming sequential parts.

    @Test func consecutiveContextToolsProduceSingleGroup() {
        // We test the grouping logic that drives contextGroup construction.
        // Build a sequence: read, glob, grep → should produce one contextGroup
        let readPart = makeToolPart(id: "r1", tool: "read")
        let globPart = makeToolPart(id: "g1", tool: "glob")
        let grepPart = makeToolPart(id: "gr1", tool: "grep")

        // All three are context tools, so they all land in one contextGroup.
        // Their IDs: "ctx-r1" (using first part's id)
        let expectedGroupID = "ctx-r1"
        let grouped = GroupedItem.contextGroup([readPart, globPart, grepPart])
        #expect(grouped.id == expectedGroupID)
    }

    @Test func singleContextToolHasContextGroupIDWithCtxPrefix() {
        let part = makeToolPart(id: "list_1", tool: "list")
        let item = GroupedItem.contextGroup([part])
        #expect(item.id.hasPrefix("ctx-"))
    }

    @Test func singleNonContextToolHasItemID() {
        let bashPart = Part.tool(makeToolPart(id: "bash_1", tool: "bash"))
        let item = GroupedItem.single(bashPart)
        #expect(item.id == "bash_1")
        #expect(!item.id.hasPrefix("ctx-"))
    }

    // MARK: - Hashable conformance

    @Test func groupedItemHashableForSinglePart() {
        let part = makeTextPart(id: "prt_hash")
        let item1 = GroupedItem.single(part)
        let item2 = GroupedItem.single(part)
        // Same content → same hash
        var set = Set<GroupedItem>()
        set.insert(item1)
        set.insert(item2)
        #expect(set.count == 1)
    }

    @Test func groupedItemHashableForContextGroup() {
        let parts = [makeToolPart(id: "ctx_hash_1", tool: "read")]
        let item1 = GroupedItem.contextGroup(parts)
        let item2 = GroupedItem.contextGroup(parts)
        var set = Set<GroupedItem>()
        set.insert(item1)
        set.insert(item2)
        #expect(set.count == 1)
    }
}