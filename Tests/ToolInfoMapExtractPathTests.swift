import Testing
import Foundation

@testable import Anvil_for_OpenCode

/// Tests for the path-extraction and filename-embedding logic added in the PR.
/// The `extractPath` and `filename` helpers are private, so we exercise them
/// through the public `info(for:input:)` interface.
@Suite("ToolInfoMap – extractPath and filename")
struct ToolInfoMapExtractPathTests {

    // MARK: - edit: title now includes filename

    @Test func editWithPathKeyIncludesFilenameInTitle() {
        let input = AnyCodable(["path": "/src/main.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit main.swift")
        #expect(info.subtitle == "/src/main.swift")
    }

    @Test func editWithFilePathKeyExtractsFilename() {
        let input = AnyCodable(["file_path": "/project/App/AppModel.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit AppModel.swift")
        #expect(info.subtitle == "/project/App/AppModel.swift")
    }

    @Test func editWithFilepathKeyExtractsFilename() {
        let input = AnyCodable(["filepath": "relative/path/foo.ts"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit foo.ts")
        #expect(info.subtitle == "relative/path/foo.ts")
    }

    @Test func editWithAbsolutePathKeyExtractsFilename() {
        let input = AnyCodable(["absolute_path": "/usr/lib/code.py"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit code.py")
        #expect(info.subtitle == "/usr/lib/code.py")
    }

    @Test func editWithAbsolutePathCamelCaseKeyExtractsFilename() {
        let input = AnyCodable(["absolutePath": "/home/user/script.sh"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit script.sh")
        #expect(info.subtitle == "/home/user/script.sh")
    }

    @Test func editWithRelativePathKeyExtractsFilename() {
        let input = AnyCodable(["relative_path": "src/utils.js"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit utils.js")
        #expect(info.subtitle == "src/utils.js")
    }

    @Test func editWithTargetKeyExtractsFilename() {
        let input = AnyCodable(["target": "/build/output.o"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit output.o")
        #expect(info.subtitle == "/build/output.o")
    }

    @Test func editWithNoPathKeyFallsBackToEditTitle() {
        let input = AnyCodable(["someOtherKey": "irrelevant"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit")
        #expect(info.subtitle == nil)
    }

    @Test func editWithNilInputFallsBackToEditTitle() {
        let info = ToolInfoMap.info(for: "edit", input: nil)
        #expect(info.title == "Edit")
        #expect(info.subtitle == nil)
    }

    // MARK: - write: title now includes filename

    @Test func writeWithPathKeyIncludesFilenameInTitle() {
        let input = AnyCodable(["path": "/output/result.json"])
        let info = ToolInfoMap.info(for: "write", input: input)
        #expect(info.title == "Write result.json")
        #expect(info.subtitle == "/output/result.json")
    }

    @Test func writeWithNoPathKeyFallsBackToWriteTitle() {
        let info = ToolInfoMap.info(for: "write", input: nil)
        #expect(info.title == "Write")
        #expect(info.subtitle == nil)
    }

    // MARK: - read: title now includes filename

    @Test func readWithPathKeyIncludesFilenameInTitle() {
        let input = AnyCodable(["path": "/docs/readme.md"])
        let info = ToolInfoMap.info(for: "read", input: input)
        #expect(info.title == "Read readme.md")
        #expect(info.subtitle == "/docs/readme.md")
    }

    @Test func readWithNoPathKeyFallsBackToReadTitle() {
        let info = ToolInfoMap.info(for: "read", input: nil)
        #expect(info.title == "Read")
        #expect(info.subtitle == nil)
    }

    // MARK: - paths array key

    @Test func editWithPathsArraySingleItemExtractsFilename() {
        let input = AnyCodable(["paths": ["/src/only.swift"]])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.subtitle == "/src/only.swift")
        #expect(info.title == "Edit only.swift")
    }

    @Test func editWithPathsArrayMultipleItemsShowsCountAnnotation() {
        let input = AnyCodable(["paths": ["/src/a.swift", "/src/b.swift", "/src/c.swift"]])
        let info = ToolInfoMap.info(for: "edit", input: input)
        // subtitle = "first (+N more)" format
        #expect(info.subtitle == "/src/a.swift (+2 more)")
        // title should strip annotation and extract filename from first path
        #expect(info.title == "Edit a.swift")
    }

    @Test func editWithFilesArrayExtractsFilename() {
        let input = AnyCodable(["files": ["/tmp/config.yaml"]])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.subtitle == "/tmp/config.yaml")
        #expect(info.title == "Edit config.yaml")
    }

    @Test func editWithFilepathsArrayMultipleItems() {
        let input = AnyCodable(["filepaths": ["/a/one.py", "/b/two.py"]])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.subtitle == "/a/one.py (+1 more)")
        #expect(info.title == "Edit one.py")
    }

    // MARK: - filename extraction edge cases (via info)

    @Test func filenameFromPathWithNoDirectoryComponent() {
        let input = AnyCodable(["path": "justfile.txt"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.title == "Edit justfile.txt")
        #expect(info.subtitle == "justfile.txt")
    }

    @Test func filenameFromPathWithExtensionlessFile() {
        let input = AnyCodable(["path": "/usr/local/bin/mytool"])
        let info = ToolInfoMap.info(for: "read", input: input)
        #expect(info.title == "Read mytool")
    }

    @Test func editSubtitlePreservesFullPath() {
        let fullPath = "/very/deep/nested/path/to/Component.tsx"
        let input = AnyCodable(["path": fullPath])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.subtitle == fullPath)
        #expect(info.title == "Edit Component.tsx")
    }

    // MARK: - icon unchanged

    @Test func editIconRemainsUnchanged() {
        let input = AnyCodable(["path": "/foo/bar.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.icon == "pencil")
    }

    @Test func writeIconRemainsUnchanged() {
        let input = AnyCodable(["path": "/foo/bar.swift"])
        let info = ToolInfoMap.info(for: "write", input: input)
        #expect(info.icon == "square.and.pencil")
    }

    @Test func readIconRemainsUnchanged() {
        let input = AnyCodable(["path": "/foo/bar.swift"])
        let info = ToolInfoMap.info(for: "read", input: input)
        #expect(info.icon == "doc.text")
    }

    // MARK: - Regression: old path= key still works (backward compat)

    @Test func editWithOldPathKeyStillReturnsSubtitle() {
        // Pre-PR: subtitle was dict["path"] as? String; post-PR uses extractPath which checks "path" first
        let input = AnyCodable(["path": "src/foo.swift"])
        let info = ToolInfoMap.info(for: "edit", input: input)
        #expect(info.subtitle == "src/foo.swift")
    }
}