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

    // MARK: - extractPath via edit / write / read (new PR behaviour)

    @Test func editWithPathKeyIncludesFilenameInTitle() {
        let input = AnyCodable(["path": "src/foo.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit foo.swift")
        #expect(info.subtitle == "src/foo.swift")
    }

    @Test func editWithFileKeyExtractsPath() {
        let input = AnyCodable(["file": "utils/helper.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit helper.swift")
        #expect(info.subtitle == "utils/helper.swift")
    }

    @Test func editWithFilePathKeyExtractsPath() {
        let input = AnyCodable(["file_path": "/project/main.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit main.swift")
        #expect(info.subtitle == "/project/main.swift")
    }

    @Test func editWithAbsolutePathKeyExtractsPath() {
        let input = AnyCodable(["absolutePath": "/Users/dev/app/App.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit App.swift")
        #expect(info.subtitle == "/Users/dev/app/App.swift")
    }

    @Test func editWithNoPathShowsGenericTitle() {
        let input = AnyCodable(["command": "irrelevant"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit")
        #expect(info.subtitle == nil)
    }

    @Test func editWithNilInputShowsGenericTitle() {
        let info = ToolInfoMap.info(for: "edit", input: nil)
        #expect(info.title == "Edit")
        #expect(info.subtitle == nil)
    }

    @Test func writeWithPathKeyIncludesFilenameInTitle() {
        let input = AnyCodable(["path": "output/result.json"])
        let info = ToolInfoMap.info(for: "write", input: input)
        #expect(info.icon == "square.and.pencil")
        #expect(info.title == "Write result.json")
        #expect(info.subtitle == "output/result.json")
    }

    @Test func writeWithNoPathShowsGenericTitle() {
        let info = ToolInfoMap.info(for: "write", input: nil)
        #expect(info.title == "Write")
        #expect(info.subtitle == nil)
    }

    @Test func readWithPathKeyIncludesFilenameInTitle() {
        let input = AnyCodable(["path": "src/main.swift"])
        let info = ToolInfoMap.info(for: "read", input: input)
        #expect(info.icon == "doc.text")
        #expect(info.title == "Read main.swift")
        #expect(info.subtitle == "src/main.swift")
    }

    @Test func readWithNoPathShowsGenericTitle() {
        let info = ToolInfoMap.info(for: "read", input: nil)
        #expect(info.title == "Read")
        #expect(info.subtitle == nil)
    }

    // MARK: - extractPath: array keys (paths / files / etc.)

    @Test func editWithPathsArraySingleItemExtractsFilename() {
        let input = AnyCodable(["paths": ["src/foo.swift"]])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit foo.swift")
        #expect(info.subtitle == "src/foo.swift")
    }

    @Test func editWithPathsArrayMultipleItemsAddsAnnotation() {
        let input = AnyCodable(["paths": ["src/a.swift", "src/b.swift", "src/c.swift"]])
        let info = ToolInfoMap.info(for: "edit", input: input)
        // subtitle has " (+2 more)" annotation
        #expect(info.subtitle == "src/a.swift (+2 more)")
        // title extracts filename from the annotated path (without the annotation)
        #expect(info.title == "Edit a.swift")
    }

    @Test func editWithFilesArraySingleItemExtractsFilename() {
        let input = AnyCodable(["files": ["components/Button.swift"]])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit Button.swift")
    }

    // MARK: - Filename extraction: path components

    @Test func deeplyNestedPathYieldsLastComponent() {
        let input = AnyCodable(["path": "/a/b/c/d/e/MyFile.swift"])
        let info = ToolInfoMap.info(for: "read", input: input)
        #expect(info.title == "Read MyFile.swift")
    }

    @Test func filenameWithNoExtensionWorks() {
        let input = AnyCodable(["path": "src/Makefile"])
        let info = ToolInfoMap.info(for: "read", input: input)
        #expect(info.title == "Read Makefile")
    }

    @Test func emptyStringPathShowsGenericTitle() {
        let input = AnyCodable(["path": ""])
        let info = ToolInfoMap.info(for: "edit", input: input)
        // empty string → no filename → generic title
        #expect(info.title == "Edit")
    }

    // MARK: - Priority: string keys take precedence over array keys

    @Test func stringKeyTakesPrecedenceOverArrayKey() {
        let input = AnyCodable(["path": "src/primary.swift", "paths": ["src/other.swift"]])
        let info = ToolInfoMap.info(for: "read", input: input)
        #expect(info.subtitle == "src/primary.swift")
        #expect(info.title == "Read primary.swift")
    }
}
