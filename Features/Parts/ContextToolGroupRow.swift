import SwiftUI

struct ContextToolGroupRow: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        Label {
            HStack(spacing: Spacing.s) {
                Text(info.title)
                if let subtitle = info.subtitle {
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: Spacing.s)
                ToolStatusIndicator(state: part.state)
            }
        } icon: {
            Image(systemName: info.icon)
        }
        .font(.callout)
    }
}
