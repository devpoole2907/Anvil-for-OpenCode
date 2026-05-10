import Foundation
import UniformTypeIdentifiers

struct PendingAttachment: Identifiable, Equatable, Sendable {
    let id: UUID
    let filename: String
    let mediaType: String
    let dataURL: String

    init(
        id: UUID = UUID(),
        filename: String,
        mediaType: String,
        dataURL: String
    ) {
        self.id = id
        self.filename = filename
        self.mediaType = mediaType
        self.dataURL = dataURL
    }

    var promptPart: PromptPart {
        .file(mediaType: mediaType, url: dataURL, filename: filename)
    }

    static func fromData(
        _ data: Data,
        filename: String,
        mediaType: String
    ) -> PendingAttachment {
        PendingAttachment(
            filename: filename,
            mediaType: mediaType,
            dataURL: "data:\(mediaType);base64,\(data.base64EncodedString())"
        )
    }

    static func fromFileURL(_ url: URL) throws -> PendingAttachment {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey, .nameKey])
        let filename = resourceValues.name ?? url.lastPathComponent
        let mediaType = resourceValues.contentType?.preferredMIMEType
            ?? UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
        return .fromData(data, filename: filename, mediaType: mediaType)
    }
}
