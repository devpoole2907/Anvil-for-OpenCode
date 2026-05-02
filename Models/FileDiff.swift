import Foundation

struct FileDiff: Codable, Identifiable, Hashable, Sendable {
    var id: String { file }
    let file: String
    let before: String?
    let after: String?
    let additions: Int?
    let deletions: Int?
}
