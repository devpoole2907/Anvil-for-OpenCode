import SwiftUI

struct ReasoningPartView: View {
    let part: ReasoningPart
    @State private var isExpanded: Bool = false

    @State private var displayedCount: Int = 0
    @State private var typewriterTask: Task<Void, Never>?

    var body: some View {
        CollapsibleSection(isExpanded: $isExpanded) {
            Label("Reasoning", systemImage: "brain")
                .foregroundStyle(.secondary)
                .font(.caption)
        } content: {
            MarkdownText(source: String(part.text.prefix(displayedCount)))
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .onAppear {
            if displayedCount < part.text.count {
                displayedCount = part.text.count
            }
        }
        .onChange(of: part.text) { oldValue, newValue in
            let commonPrefix = newValue.commonPrefix(with: oldValue)
            if commonPrefix.count == newValue.count {
                displayedCount = newValue.count
            } else {
                animateTypewriter(target: newValue, startFrom: commonPrefix.count)
            }
        }
    }

    private func animateTypewriter(target fullText: String, startFrom: Int) {
        typewriterTask?.cancel()
        displayedCount = startFrom
        guard startFrom < fullText.count else { return }
        let total = fullText.count
        typewriterTask = Task { @MainActor in
            for i in (startFrom + 1)...total {
                guard !Task.isCancelled else { break }
                displayedCount = i
                try? await Task.sleep(for: .milliseconds(15))
            }
        }
    }
}
