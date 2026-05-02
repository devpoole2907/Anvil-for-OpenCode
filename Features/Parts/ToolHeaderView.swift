import SwiftUI

struct ToolHeaderView: View {
    let info: ToolInfoMap.Info
    let state: ToolState

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: info.icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 20, height: 20)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(info.title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle = info.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: Spacing.s)
            ToolStatusIndicator(state: state)
        }
        .accessibilityElement(children: .combine)
    }

    private var iconColor: Color {
        switch state {
        case .pending: Palette.toolPending
        case .running: .accentColor
        case .completed: .primary
        case .error: Palette.toolError
        case .unknown: .secondary
        }
    }
}
