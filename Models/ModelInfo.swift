import Foundation

struct ModelCost: Codable, Hashable, Sendable {
    let input: Double?
    let output: Double?
    let cache: CacheCost?
}

struct CacheCost: Codable, Hashable, Sendable {
    let read: Double?
    let write: Double?
}

struct ModelInfo: Codable, Identifiable, Hashable, Sendable, Comparable {
    let id: String
    let providerID: String
    let name: String?
    let cost: ModelCost?

    var displayName: String { name ?? id }

    static func < (lhs: ModelInfo, rhs: ModelInfo) -> Bool {
        lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
    }
}
