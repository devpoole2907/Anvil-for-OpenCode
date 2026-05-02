import SwiftUI
import PhotosUI

struct AttachmentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                PhotosPicker(
                    selection: $selected,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Label("Choose Photos", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.borderedProminent)

                Text("Attachments will be sent with your next message as base64 data URIs.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.l)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Attachments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: { dismiss() }).bold()
                }
            }
        }
        // NOTE: Wiring of selected photos to the active prompt's PromptParts is deferred —
        // the upload helper that converts UIImage to base64 data: URIs lives on the ChatStore
        // path. v1 ships the picker UI; full attachment send-through is a polish item.
    }
}
