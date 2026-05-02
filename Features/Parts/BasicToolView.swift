import SwiftUI

struct BasicToolView<Content: View>: View {
    let info: ToolInfoMap.Info
    let state: ToolState
    let defaultOpen: Bool
    @ViewBuilder let content: Content

    @State private var isExpanded: Bool

    init(
        info: ToolInfoMap.Info,
        state: ToolState,
        defaultOpen: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.info = info
        self.state = state
        self.defaultOpen = defaultOpen
        self.content = content()
        self._isExpanded = State(initialValue: defaultOpen)
    }

    var body: some View {
        CollapsibleSection(isExpanded: $isExpanded) {
            ToolHeaderView(info: info, state: state)
        } content: {
            content
                .padding(.top, Spacing.xs)
        }
        .padding(Spacing.m)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: Radii.medium))
    }
}
