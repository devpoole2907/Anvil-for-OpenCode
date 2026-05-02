import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("ToolInfoMap")
struct ToolInfoMapTests {
    @Test func bashUsesTerminalIcon() {
        let input = AnyCodable(["command": "ls -la"])
        let info = ToolInfoMap.info(for: "bash", input: input)
        #expect(info.icon == "terminal")
        #expect(info.title == "Run command")
        #expect(info.subtitle == "ls -la")
    }

    @Test func editIncludesPathInSubtitle() {
        let input = AnyCodable(["path": "src/foo.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.icon == "pencil")
        #expect(info.subtitle == "src/foo.swift")
    }

    @Test func unknownToolFallsBack() {
        let info = ToolInfoMap.info(for: "novel-tool", input: nil)
        #expect(info.icon == "wrench.and.screwdriver")
        #expect(info.title == "Novel-Tool")
    }

    @Test func contextToolsAreFlaggedCorrectly() {
        #expect(ToolInfoMap.isContextTool("read"))
        #expect(ToolInfoMap.isContextTool("glob"))
        #expect(ToolInfoMap.isContextTool("grep"))
        #expect(ToolInfoMap.isContextTool("list"))
        #expect(!ToolInfoMap.isContextTool("bash"))
        #expect(!ToolInfoMap.isContextTool("edit"))
    }

    @Test func todosAreHidden() {
        #expect(ToolInfoMap.isHidden("todowrite"))
        #expect(ToolInfoMap.isHidden("todoread"))
        #expect(!ToolInfoMap.isHidden("bash"))
    }

    @Test func grepUsesPattern() {
        let input = AnyCodable(["pattern": "TODO"])
        let info = ToolInfoMap.info(for: "grep", input: input)
        #expect(info.icon == "magnifyingglass")
        #expect(info.subtitle == "TODO")
    }
}
