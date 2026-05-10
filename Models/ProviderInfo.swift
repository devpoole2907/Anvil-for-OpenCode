import Foundation

struct ProviderInfo: Codable, Identifiable, Hashable, Sendable, Comparable {
    let id: String
    let name: String
    let models: [ModelInfo]
    let modelTags: [String: Set<String>] // modelID -> tags

    enum CodingKeys: String, CodingKey {
        case id, name, models
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        let rawDict = try container.decodeIfPresent([String: ModelInfo].self, forKey: .models) ?? [:]
        
        // Filter out tagged entries (like "default", "max") to get the actual models list
        // and build the tag map.
        var uniqueModels: [String: ModelInfo] = [:]
        var tags: [String: Set<String>] = [:]
        
        let reservedKeys: Set<String> = ["default", "max", "reasoning", "vision"]
        
        for (key, model) in rawDict {
            if reservedKeys.contains(key) {
                tags[model.id, default: []].insert(key)
            } else {
                uniqueModels[model.id] = model
            }
        }
        
        // Ensure all models that have tags are also in the uniqueModels list
        // (sometimes the API might ONLY return them under the tag keys, though unlikely)
        for model in rawDict.values {
            if uniqueModels[model.id] == nil {
                uniqueModels[model.id] = model
            }
        }

        models = uniqueModels.values.sorted()
        modelTags = tags
    }

    static func < (lhs: ProviderInfo, rhs: ProviderInfo) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
