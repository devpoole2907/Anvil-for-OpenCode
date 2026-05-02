import Foundation
import Observation

@MainActor
@Observable
final class PermissionStore {
    var pending: [Permission] = []
    var lastError: OpencodeError?

    private let client: OpencodeClient

    init(client: OpencodeClient) {
        self.client = client
    }

    func apply(_ event: ServerEvent) {
        switch event {
        case .permissionUpdated(let permission):
            if let index = pending.firstIndex(where: { $0.id == permission.id }) {
                pending[index] = permission
            } else {
                pending.append(permission)
            }
        case .permissionReplied(let id):
            pending.removeAll { $0.id == id }
        default:
            break
        }
    }

    func respond(
        to permission: Permission,
        response: PermissionResponse,
        directory: String
    ) async {
        do {
            try await client.respondToPermission(
                id: permission.id,
                sessionID: permission.sessionID,
                directory: directory,
                response: response.wireValue,
                remember: response.remember,
                legacyResponse: response.legacyWireValue
            )
            pending.removeAll { $0.id == permission.id }
        } catch {
            lastError = OpencodeError(error)
        }
    }

    func clear() {
        pending = []
        lastError = nil
    }

    enum PermissionResponse: Sendable {
        case deny
        case allowOnce
        case allowAlways

        var wireValue: String {
            switch self {
            case .deny: "reject"
            case .allowOnce: "once"
            case .allowAlways: "always"
            }
        }

        var remember: Bool {
            if case .allowAlways = self { return true }
            return false
        }

        var legacyWireValue: String {
            switch self {
            case .deny: "deny"
            case .allowOnce: "allow"
            case .allowAlways: "always"
            }
        }
    }
}
