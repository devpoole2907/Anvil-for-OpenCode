import SwiftUI

struct MessageTimelineView: View {
    let store: ChatStore
    @State private var scrollAnchor: String?

    var body: some View {
        ScrollViewReader { proxy in
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
                        Color.clear
                            .frame(height: 1)
                            .id(MessageTimelineView.bottomAnchor)
                    }
                    .padding(.vertical, Spacing.l)
                    .frame(maxWidth: 800)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollPosition(id: $scrollAnchor, anchor: .bottom)
            .background(Color.clear)
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: store.turns.count) {
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: latestMessageID) {
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: lastPartTextLength) {
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: store.working) {
                scrollToBottom(proxy: proxy, animated: true)
            }
        }
    }

    private static let bottomAnchor = "__bottom__"

    private var lastPartTextLength: Int {
        guard let last = store.turns.last,
              case .text(let textPart) = last.assistantParts.last
        else { return 0 }
        return textPart.text.count
    }

    private var latestMessageID: String? {
        store.turns.last?.assistantMessages.last?.id ?? store.turns.last?.userMessage.id
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        scrollAnchor = MessageTimelineView.bottomAnchor
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
