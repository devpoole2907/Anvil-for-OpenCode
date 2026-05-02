import SwiftUI

struct ChatToolbar: ToolbarContent {
    let isWorking: Bool
    var onShowModels: () -> Void
    var onAbort: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            ProjectMenu()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Models", systemImage: "cpu", action: onShowModels)
                .accessibilityLabel("Choose model")
        }
        if isWorking {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Stop", systemImage: "stop.fill", role: .destructive, action: onAbort)
                    .accessibilityLabel("Stop generating")
            }
        }
    }
}
