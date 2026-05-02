import SwiftUI

struct ToolStatusIndicator: View {
    let state: ToolState

    var body: some View {
        switch state {
        case .pending:
            Image(systemName: "circle.dotted")
                .foregroundStyle(Palette.toolPending)
                .accessibilityLabel("Pending")
        case .running:
            ProgressView()
                .controlSize(.mini)
                .accessibilityLabel("Running")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Completed")
        case .error:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(Palette.toolError)
                .accessibilityLabel("Error")
        case .unknown(let state):
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Unknown status \(state.status)")
        }
    }
}
