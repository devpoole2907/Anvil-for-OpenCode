import SwiftUI

struct ContextToolGroupRow: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        HStack(spacing: Spacing.m) {
            Image(systemName: info.icon)
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            HStack(spacing: Spacing.xs) {
                Text(info.title).bold()
                if let subtitle = info.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: Spacing.s)
            ToolStatusIndicator(state: part.state)
        }
        .font(.callout)
        .padding(.vertical, 2)
    }
}
