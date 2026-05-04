import SwiftUI

struct MessageTimelineView: View {
    let store: ChatStore
    var bottomPadding: CGFloat = 0

    @State private var scrollTargetID: ScrollTargetID?

    var body: some View {
        Group {
            if store.loading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.turns.isEmpty && !store.working {
                ChatEmptyState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                timelineScrollView
            }
        }
    }

    private var timelineScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.l) {
                ForEach(store.turns) { turn in
                    TurnView(turn: turn)
                        .id(ScrollTargetID.turn(turn.id))
                        .padding(.horizontal, Spacing.l)
                }
                if showsThinkingIndicator {
                    ThinkingIndicatorView()
                        .id(ScrollTargetID.thinking)
                        .padding(.horizontal, Spacing.l)
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, Spacing.l)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .contentMargins(.bottom, max(0, bottomPadding), for: .scrollContent)
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .scrollDismissesKeyboard(.interactively)
        .scrollPosition(id: $scrollTargetID, anchor: .bottom)
        .onChange(of: bottomTargetID) { oldValue, newValue in
            guard let newValue else { return }
            let wasPinnedToBottom = oldValue == nil || scrollTargetID == nil || scrollTargetID == oldValue
            guard wasPinnedToBottom else { return }
            scrollToTarget(newValue)
        }
        .overlay(alignment: .bottomTrailing) {
            if let bottomTargetID, !isPinnedToBottom(bottomTargetID) {
                Button {
                    scrollToTarget(bottomTargetID)
                } label: {
                    Image(systemName: "arrow.down")
                        .font(.headline.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.glass)
                .tint(.accentColor)
                .padding(.trailing, Spacing.l)
                .padding(.bottom, Spacing.l + max(0, bottomPadding))
                .accessibilityLabel("Jump to latest message")
            }
        }
    }

    private var showsThinkingIndicator: Bool {
        store.working && store.turns.last?.assistantParts.isEmpty == true
    }

    private var bottomTargetID: ScrollTargetID? {
        if showsThinkingIndicator {
            return .thinking
        }
        return store.turns.last.map { .turn($0.id) }
    }

    private func isPinnedToBottom(_ bottomTargetID: ScrollTargetID) -> Bool {
        scrollTargetID == nil || scrollTargetID == bottomTargetID
    }

    private func scrollToTarget(_ target: ScrollTargetID) {
        withAnimation(.easeOut(duration: 0.2)) {
            withTransaction(\.scrollTargetAnchor, .bottom) {
                scrollTargetID = target
            }
        }
    }
}

private enum ScrollTargetID: Hashable {
    case turn(String)
    case thinking
}
