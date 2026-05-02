import Foundation

struct TextPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String
    var text: String
    var time: PartTime?
    var synthetic: Bool?

    var isSynthetic: Bool { synthetic == true }
}
