import SwiftUI

struct SessionListView: View {
    @Environment(AppModel.self) private var appModel
    @State private var searchText: String = ""
    @State private var showSettings: Bool = false
    @State private var creatingError: String?

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
        .navigationTitle("")
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
            ProjectMenu()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("New Session", systemImage: "plus", action: createSession)
                .accessibilityLabel("New session")
        }
    }

    private var sessionList: some View {
        List {
            ForEach(filteredSessions) { session in
                NavigationLink(value: session) {
                    SessionRowView(session: session)
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        delete(session)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
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
        guard let directory = appModel.projectStore.active?.directory else { return }
        Task {
            do {
                _ = try await appModel.sessionStore.create(title: nil, directory: directory)
                appModel.haptics.success()
            } catch {
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
                appModel.haptics.success()
            } catch {
                creatingError = OpencodeError(error).errorDescription
            }
        }
    }
}
