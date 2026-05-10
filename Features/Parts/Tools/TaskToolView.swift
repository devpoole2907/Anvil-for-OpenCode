import SwiftUI

struct TaskToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                // NOTE: v1 does not recurse into sub-session rendering.
                Text("Sub-agent ran")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ToolCallDetailsView(part: part)
            }
        }
    }
}
