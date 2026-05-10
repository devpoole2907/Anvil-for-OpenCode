import Foundation

enum PromptMode: String, CaseIterable, Identifiable, Codable {
    case code = "code"
    case plan = "plan"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .code: "Build"
        case .plan: "Plan"
        }
    }

    var systemImage: String {
        switch self {
        case .code: "hammer.fill"
        case .plan: "list.bullet.clipboard.fill"
        }
    }
}

enum PromptEffort: String, CaseIterable, Identifiable, Codable {
    case low, medium, high

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}
