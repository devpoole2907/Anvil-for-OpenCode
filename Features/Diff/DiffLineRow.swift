import SwiftUI

struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(prefix)
                .frame(width: 16, alignment: .center)
            Text(line.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption.monospaced())
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 1)
        .background(background)
        .accessibilityLabel(accessibility)
    }

    private var prefix: String {
        switch line.kind {
        case .context: " "
        case .addition: "+"
        case .deletion: "-"
        }
    }

    private var background: Color {
        switch line.kind {
        case .context: .clear
        case .addition: .green.opacity(0.18)
        case .deletion: .red.opacity(0.18)
        }
    }

    private var accessibility: String {
        switch line.kind {
        case .context: "Unchanged: \(line.text)"
        case .addition: "Added: \(line.text)"
        case .deletion: "Removed: \(line.text)"
        }
    }
}
