import SwiftUI

struct CollapsibleSection<Header: View, Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder let header: Header
    @ViewBuilder let content: Content

    init(
        isExpanded: Binding<Bool>,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self._isExpanded = isExpanded
        self.header = header()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: Spacing.s) {
                    header
                    Spacer(minLength: Spacing.s)
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .frame(minHeight: TapTarget.minimum)
            .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")

            if isExpanded {
                content
                    .padding(.top, Spacing.s)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }

    private func toggle() {
        isExpanded.toggle()
    }
}
