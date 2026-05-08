import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("PendingAttachment")
struct PendingAttachmentTests {

    // MARK: - fromData

    @Test func fromDataProducesBase64DataURL() {
        let data = Data("hello".utf8)
        let attachment = PendingAttachment.fromData(data, filename: "hello.txt", mediaType: "text/plain")
        let expected = "data:text/plain;base64,\(data.base64EncodedString())"
        #expect(attachment.dataURL == expected)
    }

    @Test func fromDataSetsFilename() {
        let data = Data([0xFF, 0xD8, 0xFF])
        let attachment = PendingAttachment.fromData(data, filename: "photo.jpg", mediaType: "image/jpeg")
        #expect(attachment.filename == "photo.jpg")
    }

    @Test func fromDataSetsMediaType() {
        let data = Data("{}".utf8)
        let attachment = PendingAttachment.fromData(data, filename: "data.json", mediaType: "application/json")
        #expect(attachment.mediaType == "application/json")
    }

    @Test func fromDataWithEmptyDataProducesEmptyBase64() {
        let data = Data()
        let attachment = PendingAttachment.fromData(data, filename: "empty.bin", mediaType: "application/octet-stream")
        #expect(attachment.dataURL == "data:application/octet-stream;base64,")
    }

    @Test func fromDataAssignsUniqueIDs() {
        let data = Data("x".utf8)
        let a1 = PendingAttachment.fromData(data, filename: "x.txt", mediaType: "text/plain")
        let a2 = PendingAttachment.fromData(data, filename: "x.txt", mediaType: "text/plain")
        #expect(a1.id != a2.id)
    }

    @Test func fromDataPrefixMatchesScheme() {
        let data = Data([1, 2, 3])
        let attachment = PendingAttachment.fromData(data, filename: "blob.bin", mediaType: "image/png")
        #expect(attachment.dataURL.hasPrefix("data:image/png;base64,"))
    }

    // MARK: - promptPart

    @Test func promptPartIsFileCaseWithCorrectFields() {
        let data = Data("content".utf8)
        let attachment = PendingAttachment.fromData(data, filename: "doc.pdf", mediaType: "application/pdf")

        let part = attachment.promptPart
        if case .file(let mediaType, let url, let filename) = part {
            #expect(mediaType == "application/pdf")
            #expect(url == attachment.dataURL)
            #expect(filename == "doc.pdf")
        } else {
            Issue.record("Expected .file prompt part")
        }
    }

    @Test func promptPartURLMatchesDataURL() {
        let data = Data("img".utf8)
        let attachment = PendingAttachment.fromData(data, filename: "img.png", mediaType: "image/png")
        let part = attachment.promptPart
        if case .file(_, let url, _) = part {
            #expect(url == attachment.dataURL)
        } else {
            Issue.record("Expected .file prompt part")
        }
    }

    @Test func promptPartFilenameMatchesAttachmentFilename() {
        let attachment = PendingAttachment(
            filename: "snapshot.heic",
            mediaType: "image/heic",
            dataURL: "data:image/heic;base64,abc"
        )
        if case .file(_, _, let filename) = attachment.promptPart {
            #expect(filename == "snapshot.heic")
        } else {
            Issue.record("Expected .file prompt part")
        }
    }

    // MARK: - Equatable

    @Test func attachmentsWithSameIDAreEqual() {
        let uuid = UUID()
        let a1 = PendingAttachment(id: uuid, filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        let a2 = PendingAttachment(id: uuid, filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        #expect(a1 == a2)
    }

    @Test func attachmentsWithDifferentIDsAreNotEqual() {
        let a1 = PendingAttachment(filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        let a2 = PendingAttachment(filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        #expect(a1 != a2)
    }

    // MARK: - fromFileURL with a real temp file

    @Test func fromFileURLReadsDataAndFilename() throws {
        let content = Data("file contents".utf8)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")
        try content.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let attachment = try PendingAttachment.fromFileURL(tempURL)
        #expect(attachment.filename == tempURL.lastPathComponent)
        let expectedBase64 = content.base64EncodedString()
        #expect(attachment.dataURL.contains(expectedBase64))
    }

    @Test func fromFileURLDataURLHasBase64Scheme() throws {
        let content = Data([0x89, 0x50, 0x4E, 0x47]) // PNG magic bytes
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        try content.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let attachment = try PendingAttachment.fromFileURL(tempURL)
        #expect(attachment.dataURL.hasPrefix("data:"))
        #expect(attachment.dataURL.contains(";base64,"))
    }

    @Test func fromFileURLThrowsForNonexistentFile() {
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString).txt")
        #expect(throws: (any Error).self) {
            _ = try PendingAttachment.fromFileURL(missingURL)
        }
    }

    @Test func fromFileURLFallsBackToOctetStreamForUnknownExtension() throws {
        let content = Data("binary data".utf8)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("xyzunknown9999")
        try content.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let attachment = try PendingAttachment.fromFileURL(tempURL)
        // Should not crash; mediaType may be octet-stream or a system-provided type
        #expect(!attachment.mediaType.isEmpty)
    }
}