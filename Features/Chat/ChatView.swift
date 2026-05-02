import SwiftUI

struct ChatView: View {
    let session: Session

    @Environment(AppModel.self) private var appModel
    @State private var store: ChatStore?
    @State private var showPermissionSheet: Bool = false
    @State private var showRenameAlert: Bool = false
    @State private var renameText: String = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ChatContent(
            store: store,
            permissionStore: appModel.permissionStore,
            showPermissionSheet: $showPermissionSheet,
            onSend: send,
            onInterrupt: interrupt
        )
        .navigationTitle(currentSession.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ChatNavTitle(session: currentSession)
            }
            ToolbarItem(placement: .topBarTrailing) {
                chatMenu
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            PermissionSheet()
        }
        .alert("Rename Chat", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Save", action: rename)
            Button("Cancel", role: .cancel) {}
        }
        .task(load)
        .onDisappear {
            if horizontalSizeClass == .compact {
                appModel.clearActiveChat(ifMatches: session.id)
            }
        }
    }

    // MARK: - Trailing toolbar menu

    private var chatMenu: some View {
        Menu {
            Menu {
                if mcpServerEntries.isEmpty {
                    Text("No MCP servers found")
                    Button("Reload MCP Config") {
                        refreshMCPConfig()
                    }
                } else {
                    ForEach(mcpServerEntries, id: \.name) { server in
                        Button {
                            toggleMCP(serverName: server.name, isEnabled: !server.isEnabled)
                        } label: {
                            if server.isEnabled {
                                Label(server.name, systemImage: "checkmark")
                            } else {
                                Text(server.name)
                            }
                        }
                    }
                    Divider()
                    Button("Reload MCP Config") {
                        refreshMCPConfig()
                    }
                }
            } label: {
                Label("MCP Servers", systemImage: "network")
            }

            Divider()

            // Model submenu
            Menu {
                ForEach(appModel.providerStore.providers) { provider in
                    Menu(provider.name) {
                        ForEach(provider.models) { model in
                            Button {
                                let ref = ModelRef(providerID: provider.id, modelID: model.id)
                                appModel.preferences.setDefaultModel(ref, for: appModel.activeProfile.id)
                                appModel.haptics.selection()
                            } label: {
                                let isActive = appModel.isModelActive(provider: provider, model: model)
                                HStack {
                                    if isActive {
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
                Label("Change Model", systemImage: "shuffle")
            }

            Divider()

            Button {
                share()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button {
                renameText = currentSession.title ?? ""
                showRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    // MARK: - Lifecycle

    @Sendable
    private func load() async {
        print("[ChatView] load() called for session=\(session.id) '\(session.displayTitle)'")
        let chatStore = appModel.openChat(for: session)
        store = chatStore
        guard let directory = appModel.projectStore.active?.directory else {
            print("[ChatView] load() aborted: no active directory")
            return
        }
        print("[ChatView] load() starting chatStore.load for directory=\(directory)")
        await chatStore.load(directory: directory)
        print("[ChatView] load() complete: messages=\(chatStore.messages.count) working=\(chatStore.working)")
    }

    private func send(text: String, attachments: [PendingAttachment]) {
        guard let store, let directory = appModel.projectStore.active?.directory else { return }
        let model = appModel.selectedModel
        let mode = appModel.preferences.selectedMode
        let effort = appModel.preferences.selectedEffort
        appModel.haptics.selection()
        Task {
            await store.send(
                text: text,
                attachments: attachments,
                directory: directory,
                model: model,
                mode: mode,
                effort: effort
            )
        }
    }

    private func interrupt() {
        guard let store, let directory = appModel.projectStore.active?.directory else { return }
        appModel.haptics.warning()
        Task {
            await store.interrupt(directory: directory)
        }
    }

    private func rename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let directory = appModel.projectStore.active?.directory else { return }
        Task {
            do {
                _ = try await appModel.sessionStore.rename(currentSession, title: trimmed, directory: directory)
            } catch {
                print("[ChatView] rename error: \(error)")
            }
        }
    }

    private func share() {
        guard let directory = appModel.projectStore.active?.directory else { return }
        Task {
            do {
                let updated = try await appModel.sessionStore.share(currentSession, directory: directory)
                if let urlString = updated.share?.url {
                    UIPasteboard.general.string = urlString
                    appModel.haptics.success()
                }
            } catch {
                print("[ChatView] share error: \(error)")
                appModel.haptics.error()
            }
        }
    }

    private var currentSession: Session {
        appModel.sessionStore.sessions.first(where: { $0.id == session.id }) ?? session
    }

    private var mcpServerEntries: [MCPServerEntry] {
        let servers = appModel.projectStore.config?.mcpServers ?? [:]
        return servers.keys.sorted().map { name in
            MCPServerEntry(
                name: name,
                isEnabled: !(servers[name]?.disabled ?? false)
            )
        }
    }

    private func toggleMCP(serverName: String, isEnabled: Bool) {
        guard let directory = appModel.projectStore.active?.directory else { return }
        Task {
            await appModel.projectStore.toggleMCP(
                serverName: serverName,
                disabled: !isEnabled,
                directory: directory
            )
            appModel.haptics.selection()
        }
    }

    private func refreshMCPConfig() {
        guard let directory = appModel.projectStore.active?.directory else { return }
        Task {
            await appModel.projectStore.refreshConfig(directory: directory)
        }
    }
}

private struct MCPServerEntry: Hashable {
    let name: String
    let isEnabled: Bool
}

// MARK: - Nav title (session name + workspace subtitle)

private struct ChatNavTitle: View {
    let session: Session
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 1) {
            Text(session.displayTitle)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            if let workspace = appModel.projectStore.active?.displayName {
                Text(workspace)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 44)
    }
}

// MARK: - Inner content

private struct ChatContent: View {
    let store: ChatStore?
    let permissionStore: PermissionStore
    @Binding var showPermissionSheet: Bool
    var onSend: (String, [PendingAttachment]) -> Void
    var onInterrupt: () -> Void

    @Environment(AppModel.self) private var appModel

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
                    .transition(.opacity)
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
                    .transition(.opacity)
            }

            ChatComposer(
                isWorking: store?.working ?? false,
                onSend: onSend,
                onInterrupt: onInterrupt
            )
        }
    }
}

// MARK: - Empty state

struct ChatEmptyState: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.m) {
            Spacer()

            if let project = appModel.projectStore.active {
                VStack(alignment: .center, spacing: Spacing.s) {
                    Text(project.directory)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .truncationMode(.head)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                        Text("main")
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)

                    HStack(spacing: Spacing.xs) {
                        Text("Last modified")
                            .font(.caption)
                        Text(project.time.updatedDate, format: .relative(presentation: .named))
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(Spacing.l)
                .frame(maxWidth: 320)
                .glassEffect(in: .rect(cornerRadius: Radii.large, style: .continuous))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
