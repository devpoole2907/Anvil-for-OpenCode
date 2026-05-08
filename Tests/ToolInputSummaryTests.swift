import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("ToolInputSummary")
struct ToolInputSummaryTests {

    // MARK: - Recognized keys

    @Test func pathKeyReturnsValue() {
        let dict: [String: Any] = ["path": "/src/main.swift"]
        #expect(ToolInputSummary.path(from: dict) == "/src/main.swift")
    }

    @Test func filePathCamelCaseKeyReturnsValue() {
        let dict: [String: Any] = ["filePath": "/app/Views/ContentView.swift"]
        #expect(ToolInputSummary.path(from: dict) == "/app/Views/ContentView.swift")
    }

    @Test func fileKeyReturnsValue() {
        let dict: [String: Any] = ["file": "README.md"]
        #expect(ToolInputSummary.path(from: dict) == "README.md")
    }

    @Test func fileUnderscorePathKeyReturnsValue() {
        let dict: [String: Any] = ["file_path": "/tmp/data.json"]
        #expect(ToolInputSummary.path(from: dict) == "/tmp/data.json")
    }

    @Test func filepathLowercaseKeyReturnsValue() {
        let dict: [String: Any] = ["filepath": "relative/path/script.sh"]
        #expect(ToolInputSummary.path(from: dict) == "relative/path/script.sh")
    }

    @Test func targetKeyReturnsValue() {
        let dict: [String: Any] = ["target": "/output/bundle.js"]
        #expect(ToolInputSummary.path(from: dict) == "/output/bundle.js")
    }

    // MARK: - Priority ordering

    @Test func filePathTakesPriorityOverPath() {
        // "filePath" appears first in the priority list before "path"
        let dict: [String: Any] = ["filePath": "/primary/path.swift", "path": "/secondary/path.swift"]
        #expect(ToolInputSummary.path(from: dict) == "/primary/path.swift")
    }

    @Test func pathTakesPriorityOverFile() {
        // "path" appears before "file" in the priority list
        let dict: [String: Any] = ["path": "/by/path.txt", "file": "/by/file.txt"]
        #expect(ToolInputSummary.path(from: dict) == "/by/path.txt")
    }

    // MARK: - Empty value skipped

    @Test func emptyStringValueIsSkipped() {
        let dict: [String: Any] = ["filePath": "", "path": "/fallback/file.txt"]
        #expect(ToolInputSummary.path(from: dict) == "/fallback/file.txt")
    }

    @Test func emptyStringOnlyKeyReturnsNil() {
        let dict: [String: Any] = ["filePath": ""]
        #expect(ToolInputSummary.path(from: dict) == nil)
    }

    // MARK: - No known keys

    @Test func noKnownKeysReturnsNil() {
        let dict: [String: Any] = ["command": "ls -la", "pattern": "*.swift"]
        #expect(ToolInputSummary.path(from: dict) == nil)
    }

    @Test func emptyDictReturnsNil() {
        let dict: [String: Any] = [:]
        #expect(ToolInputSummary.path(from: dict) == nil)
    }

    // MARK: - Non-string values ignored

    @Test func intValueForPathKeyIsIgnored() {
        // The method casts to String; an Int value should not match
        let dict: [String: Any] = ["path": 42, "file": "/real/path.py"]
        #expect(ToolInputSummary.path(from: dict) == "/real/path.py")
    }

    // MARK: - Regression

    @Test func relativePathIsReturnedAsIs() {
        let dict: [String: Any] = ["path": "relative/component.tsx"]
        #expect(ToolInputSummary.path(from: dict) == "relative/component.tsx")
    }

    @Test func pathWithSpacesIsReturnedUnchanged() {
        let dict: [String: Any] = ["path": "/my project/source file.swift"]
        #expect(ToolInputSummary.path(from: dict) == "/my project/source file.swift")
    }
}
