import SwiftUI

struct ReasoningPartView: View {
    let part: ReasoningPart
    @State private var isExpanded: Bool = false

    var body: some View {
        CollapsibleSection(isExpanded: $isExpanded) {
            Label("Reasoning", systemImage: "brain")
                .foregroundStyle(.secondary)
                .font(.caption)
        } content: {
            MarkdownText(source: part.text)
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }
}
