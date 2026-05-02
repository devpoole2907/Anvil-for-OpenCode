import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    var sessions: [Session] = []
    var loading: Bool = false
    var lastError: OpencodeError?

    private let client: OpencodeClient

    init(client: OpencodeClient) {
        self.client = client
    }

    func refresh(directory: String) async {
        loading = true
        defer { loading = false }
        do {
            let fetched = try await client.listSessions(directory: directory)
            sessions = fetched.sorted()
        } catch {
            lastError = OpencodeError(error)
        }
    }

    func create(title: String?, directory: String) async throws -> Session {
        let new = try await client.createSession(directory: directory, title: title)
        sessions.insert(new, at: 0)
        sessions.sort()
        return new
    }

    func delete(_ session: Session, directory: String) async throws {
        try await client.deleteSession(id: session.id, directory: directory)
        sessions.removeAll { $0.id == session.id }
    }

    func apply(_ event: ServerEvent) {
        switch event {
        case .sessionUpdated(let session):
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index] = session
            } else {
                sessions.append(session)
            }
            sessions.sort()
        case .sessionDeleted(let id):
            sessions.removeAll { $0.id == id }
        default:
            break
        }
    }

    func clear() {
        sessions = []
    }
}
