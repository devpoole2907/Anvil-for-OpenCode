import SwiftUI

struct AssistantMessageView: View {
    let message: AssistantMessage
    let parts: [Part]

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(grouped, id: \.id) { item in
                AssistantMessagePartItem(item: item, showReasoning: appModel.preferences.showReasoning)
            }
        }
    }

    /// Groups consecutive context tools (read/glob/grep/list) into a single ContextToolGroupView.
    private var grouped: [GroupedItem] {
        var result: [GroupedItem] = []
        var contextBuffer: [ToolPart] = []

        for part in parts {
            if case .tool(let toolPart) = part, ToolInfoMap.isContextTool(toolPart.tool) {
                contextBuffer.append(toolPart)
                continue
            }
            if !contextBuffer.isEmpty {
                result.append(.contextGroup(contextBuffer))
                contextBuffer = []
            }
            result.append(.single(part))
        }
        if !contextBuffer.isEmpty {
            result.append(.contextGroup(contextBuffer))
        }
        return result
    }
}

enum GroupedItem: Identifiable, Hashable {
    case single(Part)
    case contextGroup([ToolPart])

    var id: String {
        switch self {
        case .single(let part): part.id
        case .contextGroup(let parts): "ctx-\(parts.map(\.id).joined(separator: "-"))"
        }
    }
}

private struct AssistantMessagePartItem: View {
    let item: GroupedItem
    let showReasoning: Bool

    var body: some View {
        switch item {
        case .single(let part):
            switch part {
            case .text(let textPart):
                TextPartView(part: textPart)
            case .reasoning(let reasoning):
                if showReasoning {
                    ReasoningPartView(part: reasoning)
                }
            case .tool(let toolPart):
                ToolPartView(part: toolPart)
            case .compaction:
                CompactionPartView()
            case .file, .agent, .unknown:
                EmptyView()
            }
        case .contextGroup(let parts):
            ContextToolGroupView(parts: parts)
        }
    }
}
