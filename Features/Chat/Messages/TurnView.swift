import SwiftUI

struct TurnView: View {
    let turn: Turn

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            UserMessageView(turn: turn)
            ForEach(turn.assistantMessages, id: \.id) { message in
                AssistantMessageView(message: message, parts: partsFor(message: message))
            }
            ForEach(turn.assistantMessages, id: \.id) { message in
                if let summary = message.summary, let diffs = summary.diffs, !diffs.isEmpty {
                    SummaryDiffsView(diffs: diffs)
                }
                if let error = message.error {
                    AssistantErrorView(error: error)
                }
            }
        }
    }

    private func partsFor(message: AssistantMessage) -> [Part] {
        turn.assistantParts.filter { $0.messageID == message.id }
    }
}

private struct SummaryDiffsView: View {
    let diffs: [FileDiff]
    @State private var isExpanded: Bool = false

    var body: some View {
        CollapsibleSection(isExpanded: $isExpanded) {
            Label("^[\(diffs.count) file](inflect: true) modified", systemImage: "doc.badge.gearshape")
                .font(.callout.bold())
        } content: {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(diffs) { diff in
                    DiffView(diff: diff)
                }
            }
        }
    }
}

private struct AssistantErrorView: View {
    let error: AssistantError

    var body: some View {
        Label(error.displayMessage, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.1))
            .clipShape(.rect(cornerRadius: Radii.medium))
    }
}
