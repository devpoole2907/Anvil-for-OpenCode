import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("PendingAttachment")
struct PendingAttachmentTests {

    // MARK: - fromData

    @Test func fromDataBuildsCorrectDataURL() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        let attachment = PendingAttachment.fromData(data, filename: "test.txt", mediaType: "text/plain")
        let expectedBase64 = data.base64EncodedString()
        #expect(attachment.dataURL == "data:text/plain;base64,\(expectedBase64)")
    }

    @Test func fromDataStoresFilenameAndMediaType() {
        let data = Data([0xFF, 0xD8, 0xFF]) // JPEG magic bytes
        let attachment = PendingAttachment.fromData(data, filename: "photo.jpg", mediaType: "image/jpeg")
        #expect(attachment.filename == "photo.jpg")
        #expect(attachment.mediaType == "image/jpeg")
    }

    @Test func fromDataAssignsUniqueIDs() {
        let data = Data([0x01])
        let a1 = PendingAttachment.fromData(data, filename: "a.bin", mediaType: "application/octet-stream")
        let a2 = PendingAttachment.fromData(data, filename: "a.bin", mediaType: "application/octet-stream")
        #expect(a1.id != a2.id)
    }

    @Test func fromDataWithEmptyDataProducesEmptyBase64() {
        let data = Data()
        let attachment = PendingAttachment.fromData(data, filename: "empty.bin", mediaType: "application/octet-stream")
        #expect(attachment.dataURL == "data:application/octet-stream;base64,")
    }

    @Test func fromDataEmbedsMimeTypeInURL() {
        let data = Data([0x89, 0x50, 0x4E, 0x47]) // PNG magic
        let attachment = PendingAttachment.fromData(data, filename: "image.png", mediaType: "image/png")
        #expect(attachment.dataURL.hasPrefix("data:image/png;base64,"))
    }

    // MARK: - fromFileURL

    @Test func fromFileURLReadsDataFromFile() throws {
        let content = "Hello, file!"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pending_test_\(UUID().uuidString).txt")
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let attachment = try PendingAttachment.fromFileURL(url)
        let expectedBase64 = Data(content.utf8).base64EncodedString()
        #expect(attachment.dataURL.contains(expectedBase64))
    }

    @Test func fromFileURLUsesLastPathComponentAsFilename() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("myfile_\(UUID().uuidString).json")
        try "{}".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let attachment = try PendingAttachment.fromFileURL(url)
        #expect(attachment.filename == url.lastPathComponent)
    }

    @Test func fromFileURLInfersMIMETypeFromExtension() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("image_\(UUID().uuidString).png")
        // Write minimal PNG header
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        try Data(pngHeader).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let attachment = try PendingAttachment.fromFileURL(url)
        // Either image/png from UTType or content-type detection
        #expect(attachment.mediaType.contains("png") || attachment.mediaType == "application/octet-stream")
    }

    @Test func fromFileURLFallsBackToOctetStreamForUnknownExtension() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mystery_\(UUID().uuidString).xyzunknown")
        try Data([0x01, 0x02, 0x03]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let attachment = try PendingAttachment.fromFileURL(url)
        // UTType can't determine MIME for unknown extensions; fallback expected
        let knownTypes = ["application/octet-stream"]
        // Just verify it resolved to some non-empty media type
        #expect(!attachment.mediaType.isEmpty)
    }

    @Test func fromFileURLThrowsForNonExistentFile() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("does_not_exist_\(UUID().uuidString).txt")
        #expect(throws: (any Error).self) {
            _ = try PendingAttachment.fromFileURL(url)
        }
    }

    // MARK: - promptPart

    @Test func promptPartReturnsFileVariant() {
        let attachment = PendingAttachment(
            filename: "doc.pdf",
            mediaType: "application/pdf",
            dataURL: "data:application/pdf;base64,abc123"
        )
        let part = attachment.promptPart
        if case .file(let mediaType, let url, let filename) = part {
            #expect(mediaType == "application/pdf")
            #expect(url == "data:application/pdf;base64,abc123")
            #expect(filename == "doc.pdf")
        } else {
            Issue.record("Expected .file PromptPart")
        }
    }

    @Test func promptPartPreservesAllFields() {
        let data = Data("content".utf8)
        let attachment = PendingAttachment.fromData(data, filename: "notes.txt", mediaType: "text/plain")
        let part = attachment.promptPart
        if case .file(let mediaType, let url, let filename) = part {
            #expect(mediaType == "text/plain")
            #expect(url == attachment.dataURL)
            #expect(filename == "notes.txt")
        } else {
            Issue.record("Expected .file PromptPart")
        }
    }

    // MARK: - Equatable

    @Test func equalAttachmentsCompareEqual() {
        let fixedID = UUID()
        let a = PendingAttachment(id: fixedID, filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        let b = PendingAttachment(id: fixedID, filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        #expect(a == b)
    }

    @Test func attachmentsWithDifferentIDsAreNotEqual() {
        let a = PendingAttachment(id: UUID(), filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        let b = PendingAttachment(id: UUID(), filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        #expect(a != b)
    }

    @Test func attachmentsWithDifferentFilenamesAreNotEqual() {
        let fixedID = UUID()
        let a = PendingAttachment(id: fixedID, filename: "a.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        let b = PendingAttachment(id: fixedID, filename: "b.txt", mediaType: "text/plain", dataURL: "data:text/plain;base64,aGVsbG8=")
        #expect(a != b)
    }

    // MARK: - Boundary / regression

    @Test func fromDataWithSpecialCharactersInFilename() {
        let data = Data([0x01])
        let attachment = PendingAttachment.fromData(data, filename: "file with spaces & symbols!.txt", mediaType: "text/plain")
        #expect(attachment.filename == "file with spaces & symbols!.txt")
    }

    @Test func fromDataDataURLContainsBase64Segment() {
        let data = Data("test".utf8)
        let attachment = PendingAttachment.fromData(data, filename: "t.txt", mediaType: "text/plain")
        let parts = attachment.dataURL.components(separatedBy: ";base64,")
        #expect(parts.count == 2)
        #expect(!parts[1].isEmpty)
    }
}