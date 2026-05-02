import SwiftUI

struct MessageTimelineView: View {
    let store: ChatStore
    @State private var isAtBottom: Bool = true

    var body: some View {
        ScrollViewReader { proxy in
            timelineScrollView
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .scrollDismissesKeyboard(.interactively)
            .background(Color.clear)
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: store.turns) {
                scrollToBottomIfNeeded(proxy: proxy)
            }
            .onChange(of: store.working) {
                scrollToBottomIfNeeded(proxy: proxy)
            }
            .overlay(alignment: .bottomTrailing) {
                jumpToLatestButton(proxy: proxy)
            }
        }
    }

    private static let bottomAnchor = "__bottom__"

    @ViewBuilder
    private var timelineScrollView: some View {
        ScrollView {
            VStack {
                LazyVStack(alignment: .leading, spacing: Spacing.l) {
                    ForEach(store.turns) { turn in
                        TurnView(turn: turn)
                            .id(turn.id)
                            .padding(.horizontal, Spacing.l)
                    }
                    if store.working, store.turns.last?.assistantParts.isEmpty == true {
                        ThinkingIndicatorView()
                            .padding(.horizontal, Spacing.l)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, Spacing.l)
                .frame(maxWidth: 800)

                Color.clear
                    .frame(height: 1)
                    .id(MessageTimelineView.bottomAnchor)
                    .onScrollVisibilityChange(threshold: 0.2) { isVisible in
                        withAnimation(.easeOut(duration: 0.18)) {
                            isAtBottom = isVisible
                        }
                    }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func jumpToLatestButton(proxy: ScrollViewProxy) -> some View {
        if !isAtBottom {
            Button {
                scrollToBottom(proxy: proxy, animated: true)
            } label: {
                Image(systemName: "arrow.down")
                    .font(.headline.weight(.semibold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.glass)
            .tint(.accentColor)
            .padding(.trailing, Spacing.l)
            .padding(.bottom, Spacing.l)
            .accessibilityLabel("Jump to latest message")
        }
    }

    private func scrollToBottomIfNeeded(proxy: ScrollViewProxy) {
        guard isAtBottom else { return }
        scrollToBottom(proxy: proxy, animated: true)
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        let action = {
            proxy.scrollTo(MessageTimelineView.bottomAnchor, anchor: .bottom)
        }
        if animated {
            withAnimation(.easeOut(duration: 0.2), action)
        } else {
            action()
        }
    }
}
