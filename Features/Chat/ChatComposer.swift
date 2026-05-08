import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#endif

struct ChatComposer: View {
    let isWorking: Bool
    var onSend: (String, [PendingAttachment]) -> Void
    var onInterrupt: () -> Void

    @Environment(AppModel.self) private var appModel
    @State private var text: String = ""
    @State private var attachments: [PendingAttachment] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showAttachmentOptions: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var showCameraCapture: Bool = false
    @State private var attachmentError: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            composerContainer
                .frame(maxWidth: 800)
        }
        .frame(maxWidth: .infinity)
        .confirmationDialog("Add Attachment", isPresented: $showAttachmentOptions, titleVisibility: .visible) {
            Button("Choose Photos") {
                showPhotoPicker = true
            }
            Button("Choose Files") {
                showFileImporter = true
            }
            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    showCameraCapture = true
                }
            }
            #endif
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 10,
            selectionBehavior: .ordered,
            matching: .images
        )
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true,
            onCompletion: importFiles
        )
        #if os(iOS)
        .fullScreenCover(isPresented: $showCameraCapture) {
            AttachmentCameraCaptureView(
                onCapture: { attachment in
                    attachments.append(attachment)
                    showCameraCapture = false
                },
                onCancel: {
                    showCameraCapture = false
                }
            )
            .ignoresSafeArea()
        }
        #endif
        .alert("Attachment Error", isPresented: Binding(
            get: { attachmentError != nil },
            set: { if !$0 { attachmentError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(attachmentError ?? "")
        }
        .onChange(of: selectedPhotoItems) {
            guard !selectedPhotoItems.isEmpty else { return }
            importPhotos(from: selectedPhotoItems)
        }
    }

    // MARK: - Composer container

    private var composerContainer: some View {
        VStack(spacing: 0) {
            // Mode row
            modeRow
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.m)
                .padding(.bottom, Spacing.s)

            Divider()
                .opacity(0.4)

            VStack(alignment: .leading, spacing: Spacing.s) {
                if !attachments.isEmpty {
                    attachmentRow
                }
                inputRow
            }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.l)
        }
        .glassEffect(in: .rect(cornerRadius: Radii.large, style: .continuous))
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.s)
    }

    // MARK: - Mode row

    private var modeRow: some View {
        @Bindable var prefs = appModel.preferences
        return HStack(spacing: Spacing.s) {
            Menu {
                Picker("Mode", selection: $prefs.selectedMode) {
                    ForEach(PromptMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: appModel.preferences.selectedMode.systemImage)
                        .font(.caption.bold())
                    Text(appModel.preferences.selectedMode.displayName)
                        .font(.caption.bold())
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, 5)
                .background(.tertiary.opacity(0.5))
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)
            .onChange(of: prefs.selectedMode) {
                withAnimation { }
            }

            modelPicker

            effortPicker

            Spacer()
        }
    }

    private var modelPicker: some View {
        Menu {
            ForEach(appModel.providerStore.providers) { provider in
                Menu(provider.name) {
                    ForEach(provider.models) { model in
                        Button {
                            let ref = ModelRef(providerID: provider.id, modelID: model.id)
                            withAnimation {
                                appModel.preferences.setDefaultModel(ref, for: appModel.activeProfile.id)
                            }
                            appModel.haptics.selection()
                        } label: {
                            HStack {
                                if appModel.isModelActive(provider: provider, model: model) {
                                    Image(systemName: "checkmark")
                                }
                                Text(model.displayName)
                                let tags = provider.modelTags[model.id] ?? []
                                if !tags.isEmpty {
                                    Text("(\(tags.sorted().joined(separator: ", ")))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            if appModel.providerStore.providers.isEmpty {
                Text("No models available")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.caption.bold())
                Text(selectedModelNameWithTags)
                    .font(.caption.bold())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 5)
            .background(.tertiary.opacity(0.5))
            .clipShape(.capsule)
        }
    }

    private var effortPicker: some View {
        @Bindable var prefs = appModel.preferences
        return Menu {
            Picker("Effort", selection: $prefs.selectedEffort) {
                ForEach(PromptEffort.allCases) { effort in
                    Text(effort.displayName).tag(effort)
                }
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption.bold())
                Text(appModel.preferences.selectedEffort.displayName)
                    .font(.caption.bold())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 5)
            .background(.tertiary.opacity(0.5))
            .clipShape(.capsule)
        }
        .buttonStyle(.plain)
        .onChange(of: prefs.selectedEffort) {
            withAnimation { }
        }
    }

    // MARK: - Input row

    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: Spacing.s) {
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(1...8)
                .focused($isFocused)
                .disabled(isWorking)

            HStack(spacing: Spacing.s) {
                Button("Attach", systemImage: "paperclip", action: { showAttachmentOptions = true })
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Add attachment")

                sendOrStopButton
            }
        }
    }

    private var attachmentRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(attachments) { attachment in
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "paperclip")
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text(attachment.filename)
                            .font(.caption)
                            .lineLimit(1)
                        Button {
                            removeAttachment(attachment)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(attachment.filename)")
                    }
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 6)
                    .background(.tertiary.opacity(0.5))
                    .clipShape(.capsule)
                }
            }
        }
    }

    // MARK: - Send / Stop button

    private var sendOrStopButton: some View {
        Group {
            if isWorking {
                Button(action: onInterrupt) {
                    Image(systemName: "stop.fill")
                        .font(.body.bold())
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.white)
                        .background(.red, in: .circle)
                }
                .accessibilityLabel("Stop generating")
            } else {
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.body.bold())
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.white)
                        .background(
                            canSend ? Color.accentColor : Color.secondary.opacity(0.3),
                            in: .circle
                        )
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }
        }
    }

    // MARK: - Helpers

    private var canSend: Bool {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasText || !attachments.isEmpty else { return false }
        guard let ref = appModel.selectedModel,
              appModel.providerStore.model(matching: ref) != nil else { return false }
        return true
    }

    private var placeholder: String {
        isWorking ? "Working…" : "Message"
    }

    private var selectedModelNameWithTags: String {
        guard let ref = appModel.selectedModel,
              let model = appModel.providerStore.model(matching: ref) else {
            return "No Model"
        }
        let tags = appModel.tagsForModel(providerID: ref.providerID, modelID: ref.modelID)
        if tags.isEmpty {
            return model.displayName
        } else {
            return "\(model.displayName) (\(tags.sorted().joined(separator: ", ")))"
        }
    }

    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !attachments.isEmpty else { return }
        onSend(trimmed, attachments)
        text = ""
        attachments = []
    }

    private func removeAttachment(_ attachment: PendingAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }

    private func importPhotos(from items: [PhotosPickerItem]) {
        Task {
            do {
                var imported: [PendingAttachment] = []
                for (index, item) in items.enumerated() {
                    guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                    let mediaType = item.supportedContentTypes.first?.preferredMIMEType ?? "image/jpeg"
                    let filename = "Photo \(index + 1).\(item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg")"
                    imported.append(.fromData(data, filename: filename, mediaType: mediaType))
                }
                await MainActor.run {
                    attachments.append(contentsOf: imported)
                    selectedPhotoItems = []
                }
            } catch {
                await MainActor.run {
                    attachmentError = error.localizedDescription
                    selectedPhotoItems = []
                }
            }
        }
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        Task {
            do {
                let urls = try result.get()
                let imported = try urls.map(PendingAttachment.fromFileURL)
                await MainActor.run {
                    attachments.append(contentsOf: imported)
                }
            } catch {
                await MainActor.run {
                    attachmentError = error.localizedDescription
                }
            }
        }
    }
}
