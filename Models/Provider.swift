import Foundation

/// Wire shape for `GET /config/providers`.
struct ProviderListResponse: Codable, Sendable {
    let providers: [ProviderInfo]
}
