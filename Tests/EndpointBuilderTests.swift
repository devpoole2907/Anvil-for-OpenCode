import Testing
import Foundation

@testable import Anvil_for_OpenCode

@Suite("OpencodeClient URL building")
struct EndpointBuilderTests {
    private let client = OpencodeClient(
        baseURL: URL(string: "https://opencode.local:4096")!,
        username: "opencode",
        password: ""
    )

    @Test func appendsDirectoryQueryParam() throws {
        let url = try client.buildURL(path: "/session", directory: "/Users/me/work/project")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let directoryItem = components?.queryItems?.first { $0.name == "directory" }
        #expect(directoryItem?.value == "/Users/me/work/project")
    }

    @Test func omitsDirectoryWhenNil() throws {
        let url = try client.buildURL(path: "/global/health", directory: nil)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems == nil || components?.queryItems?.isEmpty == true)
    }

    @Test func escapesSpecialCharactersInDirectory() throws {
        let url = try client.buildURL(path: "/session", directory: "/path with spaces/és")
        let raw = url.absoluteString
        #expect(raw.contains("%20") || raw.contains("+"))
        #expect(raw.contains("directory="))
    }

    @Test func includesExtraQueryItems() throws {
        let url = try client.buildURL(
            path: "/file/content",
            directory: "/work",
            extraQuery: ["path": "src/main.swift"]
        )
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let pathItem = components?.queryItems?.first { $0.name == "path" }
        #expect(pathItem?.value == "src/main.swift")
    }

    @Test func basicAuthHeaderEncodesCredentials() {
        let header = BasicAuth.header(username: "opencode", password: "secret")
        #expect(header == "Basic b3BlbmNvZGU6c2VjcmV0")
    }

    @Test func basicAuthHeaderReturnsNilForEmptyPassword() {
        let header = BasicAuth.header(username: "opencode", password: "")
        #expect(header == nil)
    }
}
