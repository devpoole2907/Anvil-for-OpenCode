import Foundation
import OSLog

/// SSE event-stream consumer. Returns an `AsyncThrowingStream<ServerEvent, Error>`.
/// Reconnect strategy lives in the consumer (AppModel); when this stream finishes,
/// the consumer can decide to relaunch.
enum EventStream {
    private static let log = Logger(subsystem: "ai.opencode.client.ios", category: "EventStream")

    static func make(
        baseURL: URL,
        username: String,
        password: String,
        directory: String
    ) -> AsyncThrowingStream<ServerEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await pump(
                        baseURL: baseURL,
                        username: username,
                        password: password,
                        directory: directory,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: OpencodeError.cancelled)
                } catch {
                    continuation.finish(throwing: OpencodeError(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func pump(
        baseURL: URL,
        username: String,
        password: String,
        directory: String,
        continuation: AsyncThrowingStream<ServerEvent, Error>.Continuation
    ) async throws {
        guard var components = URLComponents(
            url: baseURL.appending(path: "/global/event"),
            resolvingAgainstBaseURL: false
        ) else {
            throw OpencodeError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "directory", value: directory)]
        guard let url = components.url else { throw OpencodeError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        if let auth = BasicAuth.header(username: username, password: password) {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = .infinity
        let session = URLSession(configuration: config)

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpencodeError.invalidResponse
        }
        switch http.statusCode {
        case 200..<300: break
        case 401, 403: throw OpencodeError.unauthenticated
        case 404: throw OpencodeError.notFound
        default: throw OpencodeError.httpStatus(http.statusCode, nil)
        }

        // Helper: SSE line accumulation. Tightly coupled — kept inline per spec.
        var accumulator = SSEAccumulator()
        let decoder = JSONDecoder()

        for try await line in bytes.lines {
            try Task.checkCancellation()
            if let payload = accumulator.consume(line: line) {
                guard let data = payload.data(using: .utf8) else { continue }
                do {
                    // Decode the outer envelope first, then extract ServerEvent.
                    let envelope = try decoder.decode(SSEEnvelope.self, from: data)
                    let event = ServerEvent(from: envelope)
                    continuation.yield(event)
                } catch {
                    log.debug("Dropping malformed SSE event: \(String(describing: error), privacy: .public)")
                    continue
                }
            }
        }
    }
}

/// SSE line accumulator. Per spec, kept private to this file as a tightly coupled helper.
private struct SSEAccumulator {
    private var dataBuffer: [String] = []
    private var eventName: String?

    mutating func consume(line: String) -> String? {
        if line.isEmpty {
            defer {
                dataBuffer.removeAll()
                eventName = nil
            }
            guard !dataBuffer.isEmpty else { return nil }
            return dataBuffer.joined(separator: "\n")
        }
        if line.hasPrefix(":") {
            return nil
        }
        if let colonIndex = line.firstIndex(of: ":") {
            let field = String(line[..<colonIndex])
            var value = String(line[line.index(after: colonIndex)...])
            if value.first == " " { value.removeFirst() }
            switch field {
            case "data": dataBuffer.append(value)
            case "event": eventName = value
            default: break
            }
        }
        return nil
    }
}
