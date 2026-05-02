import Foundation

struct HealthInfo: Codable, Sendable {
    let healthy: Bool
    let version: String
}
