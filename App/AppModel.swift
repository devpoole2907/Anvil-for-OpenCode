import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var activeProfile: ServerProfile
    private(set) var client: OpencodeClient

    private(set) var projectStore: ProjectStore
    private(set) var sessionStore: SessionStore
    private(set) var providerStore: ProviderStore
    private(set) var permissionStore: PermissionStore
    let preferences: AppPreferences
    let profileStore: ServerProfileStore
    let haptics: HapticFeedback

    var serverHealth: HealthInfo?
    var startupError: OpencodeError?
    var chatStore: ChatStore?
    var currentChatSessionID: String?

    private var eventStreamTask: Task<Void, Never>?
    private var reconnectAttempt: Int = 0

    init(
        profile: ServerProfile,
        preferences: AppPreferences,
        profileStore: ServerProfileStore
    ) {
        self.activeProfile = profile
        self.preferences = preferences
        self.profileStore = profileStore

        let newClient = OpencodeClient(
            baseURL: profile.url,
            username: profile.username,
            password: profile.password
        )
        self.client = newClient
        self.projectStore = ProjectStore(client: newClient)
        self.sessionStore = SessionStore(client: newClient)
        self.providerStore = ProviderStore(client: newClient)
        self.permissionStore = PermissionStore(client: newClient)
        self.haptics = HapticFeedback()
    }

    // MARK: - Lifecycle

    func start() async {
        do {
            serverHealth = try await client.health()
            startupError = nil
        } catch {
            startupError = OpencodeError(error)
            return
        }
        await projectStore.refresh()
        pickInitialActiveProject()
        if let active = projectStore.active {
            await loadActiveProject(directory: active.directory)
        }
    }

    func switchProfile(_ newProfile: ServerProfile) async {
        withAnimation {
            eventStreamTask?.cancel()
            eventStreamTask = nil
            chatStore = nil
            currentChatSessionID = nil
            sessionStore.clear()

            activeProfile = newProfile
            let newClient = OpencodeClient(
                baseURL: newProfile.url,
                username: newProfile.username,
                password: newProfile.password
            )
            client = newClient
            projectStore = ProjectStore(client: newClient)
            sessionStore = SessionStore(client: newClient)
            providerStore = ProviderStore(client: newClient)
            permissionStore = PermissionStore(client: newClient)
            preferences.activeProfileID = newProfile.id
        }
        await start()
    }

    func setActiveProject(_ project: Project) async {
        guard project.id != projectStore.active?.id else { return }
        withAnimation {
            eventStreamTask?.cancel()
            eventStreamTask = nil
            permissionStore.clear()
            chatStore = nil
            currentChatSessionID = nil
            projectStore.setActive(project)
            preferences.setLastActiveProject(project.id, for: activeProfile.id)
        }
        await loadActiveProject(directory: project.directory)
    }

    // MARK: - Private

    private func pickInitialActiveProject() {
        let preferredID = preferences.lastActiveProject(for: activeProfile.id)
        if let preferredID, let match = projectStore.project(matching: preferredID) {
            projectStore.setActive(match)
        } else {
            projectStore.setActive(projectStore.projects.first)
        }
    }

    private func loadActiveProject(directory: String) async {
        async let sessionsRefresh: Void = sessionStore.refresh(directory: directory)
        async let providersRefresh: Void = providerStore.refresh(directory: directory)
        async let configRefresh: Void = projectStore.refreshConfig(directory: directory)
        _ = await (sessionsRefresh, providersRefresh, configRefresh)
        startEventStream(directory: directory)
    }

    private func startEventStream(directory: String) {
        eventStreamTask?.cancel()
        let stream = client.eventStream(directory: directory)
        eventStreamTask = Task { [weak self] in
            await self?.consume(stream: stream, directory: directory)
        }
    }

    private func consume(
        stream: AsyncThrowingStream<ServerEvent, Error>,
        directory: String
    ) async {
        do {
            for try await event in stream {
                guard !Task.isCancelled else { return }
                dispatch(event)
                reconnectAttempt = 0
            }
        } catch is CancellationError {
            return
        } catch {
            // Swallow — fall through to reconnect.
        }
        await scheduleReconnect(directory: directory)
    }

    private func dispatch(_ event: ServerEvent) {
        sessionStore.apply(event)
        permissionStore.apply(event)
        chatStore?.apply(event)
    }

    private func scheduleReconnect(directory: String) async {
        guard !Task.isCancelled else { return }
        reconnectAttempt += 1
        let delay = min(30_000, 500 * Int(pow(2.0, Double(reconnectAttempt - 1))))
        try? await Task.sleep(for: .milliseconds(delay))
        guard !Task.isCancelled else { return }
        // Resync session messages on reconnect — we may have missed events.
        if let store = chatStore, let directory = projectStore.active?.directory {
            await store.load(directory: directory)
        }
        startEventStream(directory: directory)
    }

    // MARK: - Chat

    func openChat(for session: Session) -> ChatStore {
        currentChatSessionID = session.id
        if let chatStore, chatStore.sessionID == session.id {
            print("[AppModel] openChat: reusing existing store for sessionID=\(session.id)")
            return chatStore
        }
        print("[AppModel] openChat: sessionID=\(session.id) '\(session.displayTitle)'")
        let store = ChatStore(client: client, sessionID: session.id)
        chatStore = store
        return store
    }

    func closeChat() {
        chatStore = nil
        currentChatSessionID = nil
    }

    // MARK: - Models

    var selectedModel: ModelRef? {
        preferences.defaultModel(for: activeProfile.id)
            ?? providerStore.defaultModelRef()
    }

    func isModelActive(provider: ProviderInfo, model: ModelInfo) -> Bool {
        guard let active = selectedModel else { return false }
        return active.providerID == provider.id && active.modelID == model.id
    }

    func tagsForModel(providerID: String, modelID: String) -> Set<String> {
        providerStore.providers.first { $0.id == providerID }?.modelTags[modelID] ?? []
    }
}
