import SwiftUI

struct ChatView: View {
    let session: Session

    @Environment(AppModel.self) private var appModel
    @State private var store: ChatStore?
    @State private var showPermissionSheet: Bool = false
    @State private var showModelPicker: Bool = false

    var body: some View {
        ChatContent(
            store: store,
            permissionStore: appModel.permissionStore,
            showPermissionSheet: $showPermissionSheet,
            showModelPicker: $showModelPicker,
            onSend: send,
            onInterrupt: interrupt
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ChatToolbar(
                isWorking: store?.working ?? false,
                onShowModels: { showModelPicker = true },
                onAbort: interrupt
            )
        }
        .sheet(isPresented: $showPermissionSheet) {
            PermissionSheet()
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet()
        }
        .task(load)
        .onDisappear {
            appModel.closeChat()
        }
    }

    @Sendable
    private func load() async {
        let chatStore = appModel.openChat(for: session)
        store = chatStore
        guard let directory = appModel.projectStore.active?.directory else { return }
        await chatStore.load(directory: directory)
    }

    private func send(text: String) {
        guard let store, let directory = appModel.projectStore.active?.directory else { return }
        let model = appModel.preferences.defaultModel(for: appModel.activeProfile.id)
            ?? appModel.providerStore.defaultModelRef()
        appModel.haptics.selection()
        Task {
            await store.send(text: text, directory: directory, model: model)
        }
    }

    private func interrupt() {
        guard let store, let directory = appModel.projectStore.active?.directory else { return }
        appModel.haptics.warning()
        Task {
            await store.interrupt(directory: directory)
        }
    }
}

/// Inner content view so the body of `ChatView` stays focused on lifecycle and state binding.
private struct ChatContent: View {
    let store: ChatStore?
    let permissionStore: PermissionStore
    @Binding var showPermissionSheet: Bool
    @Binding var showModelPicker: Bool
    var onSend: (String) -> Void
    var onInterrupt: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !permissionStore.pending.isEmpty {
                PermissionDockView(
                    count: permissionStore.pending.count,
                    onTap: { showPermissionSheet = true }
                )
            }
            TodoDockView()

            if let store {
                MessageTimelineView(store: store)
                    .frame(maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }

            ChatComposer(
                isWorking: store?.working ?? false,
                onSend: onSend,
                onInterrupt: onInterrupt
            )
        }
    }
}
