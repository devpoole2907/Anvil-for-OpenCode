import Foundation

struct FilePart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String
    let mediaType: String?
    let filename: String?
    let url: String?
    let source: FilePartSource?
}

struct FilePartSource: Codable, Hashable, Sendable {
    let path: String?
    let text: FileSourceTextRange?
}

struct FileSourceTextRange: Codable, Hashable, Sendable {
    let start: Int
    let end: Int
    let value: String?
}
