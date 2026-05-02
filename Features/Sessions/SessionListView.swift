import SwiftUI

struct SessionListView: View {
    @Binding var selection: Session?
    var onCreatedSession: (Session) -> Void = { _ in }

    @Environment(AppModel.self) private var appModel
    @State private var searchText: String = ""
    @State private var showSettings: Bool = false
    @State private var creatingError: String?
    @State private var sessionToDelete: Session?

    var body: some View {
        Group {
            if let error = appModel.startupError {
                ContentUnavailableViews.connectionError(error, retry: retry)
            } else if appModel.projectStore.projects.isEmpty && !appModel.projectStore.loading {
                ContentUnavailableViews.noProjects()
            } else if filteredSessions.isEmpty && searchText.isEmpty && !appModel.sessionStore.loading {
                ContentUnavailableViews.noSessions(onCreate: createSession)
            } else {
                sessionList
            }
        }
        .toolbar { toolbarContent }
        .navigationTitle("Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search sessions")
        .refreshable(action: refresh)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("Couldn't create session", isPresented: errorBinding) {
            Button("OK", role: .cancel) { creatingError = nil }
        } message: {
            Text(creatingError ?? "")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Settings", systemImage: "gearshape", action: { showSettings = true })
                .accessibilityLabel("Settings")
        }
        ToolbarItem(placement: .principal) {
            WorkspaceTitleMenu()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("New Session", systemImage: "plus", action: createSession)
                .accessibilityLabel("New session")
        }
    }

    private var sessionList: some View {
        List(selection: $selection) {
            ForEach(filteredSessions) { session in
                NavigationLink(value: session) {
                    SessionRowView(session: session)
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        sessionToDelete = session
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .alert(
            "Delete Chat?",
            isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            ),
            presenting: sessionToDelete
        ) { session in
            Button("Delete", role: .destructive) {
                delete(session)
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: { session in
            Text("Are you sure you want to delete \"\(session.displayTitle)\"? This cannot be undone.")
        }
    }

    private var filteredSessions: [Session] {
        let all = appModel.sessionStore.sessions
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.displayTitle.localizedStandardContains(searchText) }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { creatingError != nil },
            set: { if !$0 { creatingError = nil } }
        )
    }

    @Sendable
    private func refresh() async {
        guard let directory = appModel.projectStore.active?.directory else { return }
        await appModel.sessionStore.refresh(directory: directory)
    }

    private func retry() {
        Task { await appModel.start() }
    }

    private func createSession() {
        guard let directory = appModel.projectStore.active?.directory else {
            print("[SessionList] createSession: no active directory")
            return
        }
        print("[SessionList] createSession: calling API for directory=\(directory)")
        Task {
            do {
                let session = try await appModel.sessionStore.create(title: nil, directory: directory)
                print("[SessionList] createSession: success, session=\(session.id)")
                appModel.haptics.success()
                onCreatedSession(session)
            } catch {
                print("[SessionList] createSession: error=\(error)")
                creatingError = OpencodeError(error).errorDescription
                appModel.haptics.error()
            }
        }
    }

    private func delete(_ session: Session) {
        guard let directory = appModel.projectStore.active?.directory else { return }
        Task {
            do {
                try await appModel.sessionStore.delete(session, directory: directory)
                withAnimation {
                    appModel.haptics.success()
                }
            } catch {
                creatingError = OpencodeError(error).errorDescription
            }
        }
    }
}

// MARK: - Workspace title menu

private struct WorkspaceTitleMenu: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Menu {
            ForEach(appModel.projectStore.projects) { project in
                Button(action: { select(project) }) {
                    if isActive(project) {
                        Label(project.displayName, systemImage: "checkmark")
                    } else {
                        Text(project.displayName)
                    }
                }
            }
            if appModel.projectStore.projects.isEmpty {
                Text("No workspaces available")
            }
        } label: {
            VStack(spacing: 1) {
                HStack(spacing: 4) {
                    Text(appModel.projectStore.active?.displayName ?? "Choose workspace")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Image(systemName: "chevron.down")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                Text("Workspace")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let active = appModel.projectStore.active {
            "Switch workspace, currently \(active.displayName)"
        } else {
            "Choose a workspace"
        }
    }

    private func isActive(_ project: Project) -> Bool {
        appModel.projectStore.active?.id == project.id
    }

    private func select(_ project: Project) {
        Task {
            await appModel.setActiveProject(project)
        }
    }
}
