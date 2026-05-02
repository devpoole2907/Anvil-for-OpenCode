import SwiftUI

struct ChatComposer: View {
    let isWorking: Bool
    var onSend: (String) -> Void
    var onInterrupt: () -> Void

    @State private var text: String = ""
    @State private var showAttachments: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: Spacing.s) {
                Button("Attach", systemImage: "paperclip", action: { showAttachments = true })
                    .labelStyle(.iconOnly)
                    .frame(minWidth: TapTarget.minimum, minHeight: TapTarget.minimum)
                    .accessibilityLabel("Add attachment")

                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(1...8)
                    .focused($isFocused)
                    .disabled(isWorking)
                    .padding(Spacing.s)
                    .background(.thinMaterial)
                    .clipShape(.rect(cornerRadius: Radii.medium))

                sendOrStopButton
            }
            .padding(Spacing.s)
            .background(.regularMaterial)
        }
        .sheet(isPresented: $showAttachments) {
            AttachmentPickerSheet()
        }
    }

    private var placeholder: String {
        isWorking ? "Working…" : "Send a message"
    }

    private var sendOrStopButton: some View {
        Group {
            if isWorking {
                Button("Stop", systemImage: "stop.fill", role: .destructive, action: onInterrupt)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityLabel("Stop generating")
            } else {
                Button("Send", systemImage: "arrow.up.circle.fill", action: send)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send message")
            }
        }
        .frame(minWidth: TapTarget.minimum, minHeight: TapTarget.minimum)
    }

    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        text = ""
    }
}
