import SwiftUI

struct ContextToolGroupView: View {
    let parts: [ToolPart]
    @State private var isExpanded: Bool = false

    var body: some View {
        let info = ToolInfoMap.Info(
            icon: "doc.text.magnifyingglass",
            title: "Gathered context",
            subtitle: subtitleText
        )
        BasicToolView(info: info, state: aggregateState, defaultOpen: false) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(parts) { part in
                    ContextToolGroupRow(part: part)
                }
            }
        }
    }

    private var subtitleText: String {
        var counts: [String: Int] = [:]
        for part in parts {
            counts[part.tool, default: 0] += 1
        }
        return counts
            .sorted { $0.key < $1.key }
            .map { "\($0.value) \($0.key)\($0.value == 1 ? "" : "s")" }
            .joined(separator: ", ")
    }

    /// If any sub-tool errored, show error; if any are still running, show running; else completed.
    private var aggregateState: ToolState {
        if let errored = parts.first(where: { if case .error = $0.state { true } else { false } }) {
            return errored.state
        }
        if let running = parts.first(where: { if case .running = $0.state { true } else { false } }) {
            return running.state
        }
        if let last = parts.last,
           parts.allSatisfy({ if case .completed = $0.state { true } else { false } }) {
            return last.state
        }
        return parts.first?.state ?? .pending(ToolStatePending(status: "pending"))
    }
}
