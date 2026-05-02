import Foundation

struct ConfigInfo: Codable, Sendable {
    let model: String?
    let theme: String?
    let agents: AnyCodable?
}
