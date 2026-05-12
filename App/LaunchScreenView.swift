import SwiftUI

/// Plain placeholder shown while RootView decides which screen to present.
/// Kept minimal so the launch experience matches the static launch screen.
struct LaunchScreenView: View {
    var onEditServer: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.l) {
            ProgressView()
            Text("Loading…")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let onEditServer {
                Button("Edit Server", action: onEditServer)
                    .buttonStyle(.bordered)
                    .padding(.top, Spacing.m)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
