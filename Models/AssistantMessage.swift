import Foundation

struct AssistantMessage: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let role: String
    let sessionID: String
    let parentID: String?
    let providerID: String?
    let modelID: String?
    let time: MessageTime
    let cost: Double?
    let tokens: TokenUsage?
    let summary: AssistantSummary?
    let error: AssistantError?
}
