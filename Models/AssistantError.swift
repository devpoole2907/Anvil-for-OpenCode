import Foundation

struct AssistantError: Codable, Hashable, Sendable {
    let name: String
    let data: AnyCodable?

    var displayMessage: String {
        if let data, let dict = data.dictionaryValue, let message = dict["message"] as? String {
            return message
        }
        return name
    }
}
