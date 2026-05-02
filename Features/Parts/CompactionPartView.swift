import SwiftUI

struct CompactionPartView: View {
    var body: some View {
        HStack(spacing: Spacing.s) {
            VStack { Divider() }
            Text("Context compacted")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack { Divider() }
        }
        .padding(.vertical, Spacing.s)
        .accessibilityElement(children: .combine)
    }
}
