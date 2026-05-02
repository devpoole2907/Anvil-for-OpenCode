import SwiftUI

struct MessageTimelineView: View {
    let store: ChatStore
    @State private var scrollAnchor: String?
    @State private var isUserScrolled: Bool = false

    var body: some View {
        ScrollView {
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
        }
        .scrollPosition(id: $scrollAnchor, anchor: .bottom)
        .onChange(of: store.turns.count) {
            scrollToBottomIfNeeded()
        }
        .onChange(of: lastPartTextLength) {
            scrollToBottomIfNeeded()
        }
    }

    private static let bottomAnchor = "__bottom__"

    private var lastPartTextLength: Int {
        guard let last = store.turns.last,
              case .text(let textPart) = last.assistantParts.last
        else { return 0 }
        return textPart.text.count
    }

    private func scrollToBottomIfNeeded() {
        // NOTE: With ScrollView's `scrollPosition`, anchoring to the bottom sentinel
        // produces auto-scroll on new content. A future polish: detect manual scroll
        // and only auto-scroll when the user is near the bottom.
        scrollAnchor = MessageTimelineView.bottomAnchor
    }
}
