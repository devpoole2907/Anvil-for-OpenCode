import Foundation

struct TokenUsage: Codable, Hashable, Sendable {
    let input: Int?
    let output: Int?
    let reasoning: Int?
    let cache: CacheTokens?

    var total: Int {
        (input ?? 0) + (output ?? 0) + (reasoning ?? 0)
    }
}

struct CacheTokens: Codable, Hashable, Sendable {
    let read: Int?
    let write: Int?
}
