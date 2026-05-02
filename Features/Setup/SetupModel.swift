import Foundation
import Observation

@MainActor
@Observable
final class SetupModel {
    enum TestStatus: Equatable {
        case idle
        case testing
        case ok(version: String)
        case failed(message: String)
    }

    var name: String = ""
    var urlText: String = ""
    var username: String = "opencode"
    var password: String = ""
    var testStatus: TestStatus = .idle

    var canSubmit: Bool {
        !name.isEmpty && parsedURL != nil && !username.isEmpty
    }

    var parsedURL: URL? {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "http" || url.scheme == "https"
        else { return nil }
        return url
    }

    func test() async {
        guard let url = parsedURL else {
            testStatus = .failed(message: "Enter a valid http(s) URL.")
            return
        }
        testStatus = .testing
        let client = OpencodeClient(baseURL: url, username: username, password: password)
        do {
            let health = try await client.health()
            testStatus = .ok(version: health.version)
        } catch {
            let opencode = OpencodeError(error)
            testStatus = .failed(message: opencode.errorDescription ?? "Couldn't reach the server.")
        }
    }

    func build() -> ServerProfile? {
        guard let url = parsedURL else { return nil }
        return ServerProfile(name: name, url: url, username: username, password: password)
    }
}
