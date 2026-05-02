import SwiftUI

/// Plain placeholder shown while RootView decides which screen to present.
/// Kept minimal so the launch experience matches the static launch screen.
struct LaunchScreenView: View {
    var body: some View {
        VStack(spacing: Spacing.l) {
            ProgressView()
            Text("Loading…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
