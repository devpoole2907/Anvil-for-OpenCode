import SwiftUI

struct ToolHeaderView: View {
    let info: ToolInfoMap.Info
    let state: ToolState

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: info.icon)
                .frame(width: 24, height: 24)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(info.title).bold()
                if let subtitle = info.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
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
