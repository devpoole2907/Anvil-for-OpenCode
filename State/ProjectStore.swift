import Foundation
import Observation

@MainActor
@Observable
final class ProjectStore {
    var projects: [Project] = []
    var active: Project?
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

    func setActive(_ project: Project?) {
        active = project
    }

    func project(matching id: String) -> Project? {
        projects.first { $0.id == id }
    }
}
