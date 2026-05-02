import Foundation

struct ProviderInfo: Codable, Identifiable, Hashable, Sendable, Comparable {
    let id: String
    let name: String
    let models: [ModelInfo]

    enum CodingKeys: String, CodingKey {
        case id, name, models
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let modelsDict = try container.decodeIfPresent([String: ModelInfo].self, forKey: .models) ?? [:]
        models = modelsDict.values.sorted()
    }

    static func < (lhs: ProviderInfo, rhs: ProviderInfo) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
