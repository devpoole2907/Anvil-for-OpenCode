import SwiftUI

struct PermissionDockView: View {
    let count: Int
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text("^[\(count) permission request](inflect: true)")
                    .font(.callout.bold())
                Spacer(minLength: Spacing.s)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .frame(maxWidth: .infinity, minHeight: TapTarget.minimum)
            .background(.orange.opacity(0.15))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) permission requests pending. Tap to review.")
    }
}
