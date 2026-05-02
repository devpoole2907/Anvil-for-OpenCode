import Foundation
import Observation

@MainActor
@Observable
final class ProjectStore {
    var projects: [Project] = []
    var active: Project?
    var config: ConfigInfo?
    var loading: Bool = false
    var lastError: OpencodeError?

    private let client: OpencodeClient

    init(client: OpencodeClient) {
        self.client = client
    }

    func refresh() async {
        loading = true
        defer { loading = false }
        do {
            let fetched = try await client.projects()
            projects = fetched.sorted()
        } catch {
            lastError = OpencodeError(error)
        }
    }

    func refreshConfig(directory: String) async {
        do {
            config = try await client.config(directory: directory)
        } catch {
            print("[ProjectStore] refreshConfig error: \(error)")
        }
    }

    func toggleMCP(serverName: String, disabled: Bool, directory: String) async {
        do {
            try await client.toggleMCP(serverName: serverName, disabled: disabled, directory: directory)
            // Optimistically update local config state
            if config?.mcpServers != nil {
                config!.mcpServers![serverName]?.disabled = disabled
            }
        } catch {
            print("[ProjectStore] toggleMCP error: \(error)")
        }
    }

    func setActive(_ project: Project?) {
        active = project
    }

    func project(matching id: String) -> Project? {
        projects.first { $0.id == id }
    }
}
