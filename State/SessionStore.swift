import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    var sessions: [Session] = []
    var busySessionIDs: Set<String> = []
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
        busySessionIDs.remove(session.id)
    }

    func rename(_ session: Session, title: String, directory: String) async throws -> Session {
        let updated = try await client.updateSessionTitle(id: session.id, directory: directory, title: title)
        if let index = sessions.firstIndex(where: { $0.id == updated.id }) {
            sessions[index] = updated
        }
        return updated
    }

    func share(_ session: Session, directory: String) async throws -> Session {
        let updated = try await client.shareSession(id: session.id, directory: directory)
        if let index = sessions.firstIndex(where: { $0.id == updated.id }) {
            sessions[index] = updated
        }
        return updated
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
            busySessionIDs.remove(id)
        case .sessionStatus(let id, let status):
            if status == "busy" {
                busySessionIDs.insert(id)
            } else {
                busySessionIDs.remove(id)
            }
        default:
            break
        }
    }

    func isSessionBusy(_ sessionID: String) -> Bool {
        busySessionIDs.contains(sessionID)
    }

    func clear() {
        sessions = []
        busySessionIDs = []
    }
}
