import SwiftUI

struct MessageTimelineView: View {
    let store: ChatStore
    var bottomPadding: CGFloat = 0

    @State private var isPinnedToBottom: Bool = true
    @State private var contentHeight: CGFloat = 0

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
        ScrollViewReader { proxy in
            ScrollView {
                // Regular VStack (not lazy) so all items render immediately on appear.
                // LazyVStack caused a blank + scroll glitch: items only rendered when the
                // viewport reached them, but the viewport started at the top (empty content),
                // so defaultScrollAnchor(.bottom) had no real height to anchor against.
                VStack(alignment: .leading, spacing: Spacing.l) {
                    ForEach(store.turns) { turn in
                        TurnView(turn: turn)
                            .padding(.horizontal, Spacing.l)
                    }
                    if showsThinkingIndicator {
                        ThinkingIndicatorView()
                            .padding(.horizontal, Spacing.l)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id(ScrollTargetID.sentinel)
                }
                .padding(.vertical, Spacing.l)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { newHeight in
                    defer { contentHeight = newHeight }
                    guard newHeight > contentHeight, isPinnedToBottom else { return }
                    proxy.scrollTo(ScrollTargetID.sentinel, anchor: .bottom)
                }
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .contentMargins(.bottom, max(0, bottomPadding), for: .scrollContent)
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentSize.height - geometry.visibleRect.maxY < 80
            } action: { _, isNearBottom in
                isPinnedToBottom = isNearBottom
            }
            .onChange(of: scrollTrigger) { oldValue, newValue in
                guard newValue.bottomTargetID != nil else { return }
                guard isPinnedToBottom || oldValue.bottomTargetID == nil else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(ScrollTargetID.sentinel, anchor: .bottom)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !isPinnedToBottom {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(ScrollTargetID.sentinel, anchor: .bottom)
                        }
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
    }

    private var showsThinkingIndicator: Bool {
        store.working && (store.turns.isEmpty || store.turns.last?.assistantParts.isEmpty == true)
    }

    private var bottomTargetID: ScrollTargetID? {
        if showsThinkingIndicator { return .thinking }
        return store.turns.last.map { .turn($0.id) }
    }

    private var scrollTrigger: ScrollTrigger {
        let lastTurn = store.turns.last
        return ScrollTrigger(
            turnCount: store.turns.count,
            lastTurnID: lastTurn?.id,
            lastAssistantMessageID: lastTurn?.assistantMessages.last?.id,
            assistantPartCount: lastTurn?.assistantParts.count ?? 0,
            showsThinking: showsThinkingIndicator,
            bottomTargetID: bottomTargetID
        )
    }
}

private enum ScrollTargetID: Hashable {
    case turn(String)
    case thinking
    case sentinel
}

private struct ScrollTrigger: Equatable {
    var turnCount: Int
    var lastTurnID: String?
    var lastAssistantMessageID: String?
    var assistantPartCount: Int
    var showsThinking: Bool
    var bottomTargetID: ScrollTargetID?
}
