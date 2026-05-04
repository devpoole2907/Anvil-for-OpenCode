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
            let serverNames = config?.mcpServers?.keys.sorted() ?? []
            print("[ProjectStore] refreshConfig directory=\(directory)")
            print("[ProjectStore] decoded MCP servers count=\(serverNames.count) names=\(serverNames)")
        } catch {
            print("[ProjectStore] refreshConfig error for directory=\(directory): \(error)")
            lastError = OpencodeError(error)
        }
    }

    func toggleMCP(serverName: String, disabled: Bool, directory: String) async {
        do {
            print("[ProjectStore] toggleMCP server=\(serverName) disabled=\(disabled) directory=\(directory)")
            guard var serverConfig = config?.mcpServers?[serverName] else {
                print("[ProjectStore] toggleMCP missing config for server=\(serverName)")
                return
            }
            serverConfig.enabled = !disabled
            serverConfig.disabled = disabled
            try await client.toggleMCP(serverName: serverName, config: serverConfig, directory: directory)
            // Optimistically update local config state
            if config?.mcpServers != nil {
                config!.mcpServers![serverName] = serverConfig
            }
            print("[ProjectStore] toggleMCP updated local config for server=\(serverName)")
        } catch {
            print("[ProjectStore] toggleMCP error for server=\(serverName): \(error)")
            lastError = OpencodeError(error)
        }
    }

    func addProject(directory: String) -> Project {
        let id = directory.replacingOccurrences(of: "/", with: "-")
        let project = Project(id: id, worktree: directory, name: nil, time: TimeRange(created: Date.now.timeIntervalSince1970, updated: Date.now.timeIntervalSince1970))
        projects = [project] + projects
        return project
    }

    func setActive(_ project: Project?) {
        active = project
    }

    func project(matching id: String) -> Project? {
        projects.first { $0.id == id }
    }
}
