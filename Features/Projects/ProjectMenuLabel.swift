import SwiftUI

struct ProjectMenuLabel: View {
    let name: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(name)
                .lineLimit(1)
                .truncationMode(.middle)
                .bold()
            Image(systemName: "chevron.down")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: TapTarget.minimum)
        .contentShape(.rect)
    }
}
