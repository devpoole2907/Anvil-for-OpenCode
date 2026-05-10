import Foundation

struct PromptBody: Encodable, Sendable {
    let parts: [PromptPart]
    var model: ModelRef?
    var mode: String?
    var effort: String?
    var agent: String?
    var system: String?
}

enum PromptPart: Encodable, Sendable {
    case text(String)
    case file(mediaType: String, url: String, filename: String?)

    private enum CodingKeys: String, CodingKey {
        case type, text, mediaType, url, filename
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        case .file(let mediaType, let url, let filename):
            try container.encode("file", forKey: .type)
            try container.encode(mediaType, forKey: .mediaType)
            try container.encode(url, forKey: .url)
            try container.encodeIfPresent(filename, forKey: .filename)
        }
    }
}
