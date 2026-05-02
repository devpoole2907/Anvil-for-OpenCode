import Foundation

/// Networking actor for the opencode HTTP API.
/// All endpoint methods are `async throws` and serialise on the actor's executor.
/// The streaming SSE method is `nonisolated` so the long-lived task doesn't block the actor.
actor OpencodeClient {
    let baseURL: URL
    let username: String
    private let password: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)

        // NOTE: opencode mostly uses camelCase. Default decoding strategy works.
        // Verify against the user's running server during integration; flip to
        // .convertFromSnakeCase if a key mismatch surfaces.
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Health & Discovery

    func health() async throws -> HealthInfo {
        try await get("/global/health", directory: nil)
    }

    // MARK: - Projects

    func projects() async throws -> [Project] {
        try await get("/project", directory: nil)
    }

    func currentProject(directory: String?) async throws -> Project? {
        do {
            return try await get("/project/current", directory: directory) as Project
        } catch OpencodeError.notFound {
            return nil
        }
    }

    // MARK: - Config & Providers

    func config(directory: String) async throws -> ConfigInfo {
        let data = try await performRequest(method: .get, path: "/config", directory: directory, body: Optional<EmptyBody>.none)
        if let body = String(data: data, encoding: .utf8) {
            print("[OpencodeClient] /config raw response for directory=\(directory): \(body)")
        } else {
            print("[OpencodeClient] /config raw response for directory=\(directory): <non-UTF8 \(data.count) bytes>")
        }
        do {
            let decoded = try decoder.decode(ConfigInfo.self, from: data)
            let names = decoded.mcpServers?.keys.sorted() ?? []
            print("[OpencodeClient] /config decoded MCP servers: \(names)")
            return decoded
        } catch {
            print("[OpencodeClient] /config decode error: \(error)")
            throw OpencodeError.decoding(String(describing: error))
        }
    }

    func toggleMCP(serverName: String, config: MCPConfig, directory: String) async throws {
        struct MCPPatch: Encodable {
            let mcp: [String: MCPConfig]
        }
        let body = MCPPatch(mcp: [serverName: config])
        if let data = try? encoder.encode(body),
           let rawBody = String(data: data, encoding: .utf8) {
            print("[OpencodeClient] toggleMCP request body for server=\(serverName): \(rawBody)")
        }
        try await sendVoid(.patch, "/config", directory: directory, body: body)
    }

    func providers(directory: String) async throws -> ProviderListResponse {
        try await get("/config/providers", directory: directory)
    }

    // MARK: - Sessions

    func listSessions(directory: String) async throws -> [Session] {
        try await get("/session", directory: directory)
    }

    func createSession(directory: String, title: String?) async throws -> Session {
        struct Body: Encodable { let title: String? }
        return try await post("/session", directory: directory, body: Body(title: title))
    }

    func session(id: String, directory: String) async throws -> Session {
        try await get("/session/\(id)", directory: directory)
    }

    func updateSessionTitle(id: String, directory: String, title: String) async throws -> Session {
        struct Body: Encodable { let title: String }
        return try await send(.patch, "/session/\(id)", directory: directory, body: Body(title: title))
    }

    func shareSession(id: String, directory: String) async throws -> Session {
        return try await send(.post, "/session/\(id)/share", directory: directory, body: Optional<EmptyBody>.none)
    }

    func deleteSession(id: String, directory: String) async throws {
        try await sendVoid(.delete, "/session/\(id)", directory: directory)
    }

    func messages(sessionID: String, directory: String) async throws -> [MessageEnvelope] {
        try await get("/session/\(sessionID)/message", directory: directory)
    }

    // MARK: - Prompting

    /// POSTs a prompt; UI streaming is driven by SSE, not by awaiting this body.
    func sendPrompt(sessionID: String, directory: String, body: PromptBody) async throws {
        do {
            try await sendVoid(.post, "/session/\(sessionID)/prompt_async", directory: directory, body: body)
        } catch OpencodeError.notFound {
            do {
                try await sendVoid(.post, "/session/\(sessionID)/prompt", directory: directory, body: body)
            } catch OpencodeError.notFound {
                try await sendVoid(.post, "/session/\(sessionID)/message", directory: directory, body: body)
            }
        }
    }

    func interrupt(sessionID: String, directory: String) async throws {
        do {
            try await sendVoid(.post, "/session/\(sessionID)/abort", directory: directory)
        } catch OpencodeError.notFound {
            try await sendVoid(.post, "/session/\(sessionID)/interrupt", directory: directory)
        }
    }

    // MARK: - Permissions

    func respondToPermission(
        id: String,
        sessionID: String,
        directory: String,
        response: String,
        remember: Bool,
        legacyResponse: String
    ) async throws {
        struct Body: Encodable {
            let response: String
            let remember: Bool
        }
        do {
            try await sendVoid(
                .post,
                "/session/\(sessionID)/permissions/\(id)",
                directory: directory,
                body: Body(response: response, remember: remember)
            )
        } catch OpencodeError.notFound {
            try await sendVoid(
                .post,
                "/permission/\(id)",
                directory: directory,
                body: Body(response: legacyResponse, remember: remember)
            )
        }
    }

    // MARK: - Streaming

    /// Long-lived SSE event stream. Nonisolated so the async sequence isn't pinned to the actor.
    nonisolated func eventStream(directory: String) -> AsyncThrowingStream<ServerEvent, Error> {
        EventStream.make(
            baseURL: baseURL,
            username: username,
            password: password,
            directory: directory
        )
    }

    // MARK: - URL building

    nonisolated func buildURL(path: String, directory: String?, extraQuery: [String: String] = [:]) throws -> URL {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw OpencodeError.invalidURL
        }
        var items = components.queryItems ?? []
        if let directory {
            items.append(URLQueryItem(name: "directory", value: directory))
        }
        for (key, value) in extraQuery {
            items.append(URLQueryItem(name: key, value: value))
        }
        if !items.isEmpty {
            components.queryItems = items
        }
        guard let url = components.url else {
            throw OpencodeError.invalidURL
        }
        return url
    }

    nonisolated func authHeader() -> String? {
        BasicAuth.header(username: username, password: password)
    }

    // MARK: - Request helpers

    private func get<T: Decodable>(_ path: String, directory: String?) async throws -> T {
        try await send(.get, path, directory: directory, body: Optional<EmptyBody>.none)
    }

    private func post<Body: Encodable, T: Decodable>(
        _ path: String,
        directory: String?,
        body: Body
    ) async throws -> T {
        try await send(.post, path, directory: directory, body: body)
    }

    private func send<Body: Encodable, T: Decodable>(
        _ method: HTTPMethod,
        _ path: String,
        directory: String?,
        body: Body?
    ) async throws -> T {
        let data = try await performRequest(method: method, path: path, directory: directory, body: body)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw OpencodeError.decoding(String(describing: error))
        }
    }

    private func sendVoid(
        _ method: HTTPMethod,
        _ path: String,
        directory: String?,
        body: (some Encodable)? = Optional<EmptyBody>.none
    ) async throws {
        _ = try await performRequest(method: method, path: path, directory: directory, body: body)
    }

    private func performRequest<Body: Encodable>(
        method: HTTPMethod,
        path: String,
        directory: String?,
        body: Body?
    ) async throws -> Data {
        let url = try buildURL(path: path, directory: directory)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let auth = authHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OpencodeError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw OpencodeError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw OpencodeError.unauthenticated
        case 404:
            throw OpencodeError.notFound
        case 409, 423:
            throw OpencodeError.serverBusy
        default:
            let body = String(data: data, encoding: .utf8)
            throw OpencodeError.httpStatus(http.statusCode, body)
        }
    }

    private struct EmptyBody: Encodable {}
}
