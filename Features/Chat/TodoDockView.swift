import SwiftUI

/// Docked summary of the agent's todo list. Collapsed by default; expands inline.
/// NOTE: v1 reads todos from the latest `todowrite` tool part it can find on the
/// current chat store. The full todos-by-session-channel surface is a v2 polish.
struct TodoDockView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isExpanded: Bool = false

    var body: some View {
        if !todos.isEmpty {
            VStack(spacing: 0) {
                CollapsibleSection(isExpanded: $isExpanded) {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "checklist")
                            .accessibilityHidden(true)
                        Text(summary)
                            .font(.callout)
                    }
                } content: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(todos) { todo in
                            TodoRow(todo: todo)
                        }
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
                Divider()
            }
            .background(.thinMaterial)
        }
    }

    private var todos: [Todo] {
        guard let chatStore = appModel.chatStore else { return [] }
        let toolParts = chatStore.parts.values.flatMap { $0 }.compactMap { part -> ToolPart? in
            if case .tool(let toolPart) = part { return toolPart }
            return nil
        }
        let todoTools = toolParts.filter { $0.tool == "todowrite" || $0.tool == "todoread" }
        guard let latest = todoTools.last,
              let dict = latest.state.input?.dictionaryValue,
              let raw = dict["todos"] as? [[String: Any]]
        else { return [] }
        return raw.compactMap { entry in
            guard let content = entry["content"] as? String,
                  let status = entry["status"] as? String
            else { return nil }
            return Todo(content: content, status: status, priority: entry["priority"] as? String)
        }
    }

    private var summary: String {
        let total = todos.count
        let inProgress = todos.count(where: { $0.resolvedStatus == .inProgress })
        let completed = todos.count(where: { $0.resolvedStatus == .completed })
        return "\(total) todos · \(inProgress) in progress · \(completed) done"
    }
}

private struct TodoRow: View {
    let todo: Todo

    var body: some View {
        Label {
            Text(todo.content)
                .strikethrough(todo.resolvedStatus == .completed)
                .foregroundStyle(todo.resolvedStatus == .completed ? .secondary : .primary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
        }
        .font(.callout)
    }

    private var icon: String {
        switch todo.resolvedStatus {
        case .pending: "circle"
        case .inProgress: "circle.dotted"
        case .completed: "checkmark.circle.fill"
        case .unknown: "questionmark.circle"
        }
    }

    private var iconColor: Color {
        switch todo.resolvedStatus {
        case .pending: .secondary
        case .inProgress: .accentColor
        case .completed: .green
        case .unknown: .secondary
        }
    }
}
