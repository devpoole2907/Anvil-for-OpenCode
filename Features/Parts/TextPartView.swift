import SwiftUI

struct TextPartView: View {
    let part: TextPart

    @State private var displayedCount: Int = 0
    @State private var typewriterTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            MarkdownText(source: String(part.text.prefix(displayedCount)))
            HStack {
                Spacer()
                CopyButton(text: part.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Show full existing text immediately (no animation on first render or page-back).
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
