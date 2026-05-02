import Foundation

enum OpencodeError: Error, LocalizedError, Sendable {
    case httpStatus(Int, String?)
    case decoding(String)
    case transport(String)
    case unauthenticated
    case notFound
    case serverBusy
    case cancelled
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .httpStatus(let code, let body):
            if let body, !body.isEmpty {
                "Server returned HTTP \(code): \(body)"
            } else {
                "Server returned HTTP \(code)."
            }
        case .decoding(let detail):
            "Couldn't decode the server response. \(detail)"
        case .transport(let detail):
            "Network error: \(detail)"
        case .unauthenticated:
            "The username or password is incorrect."
        case .notFound:
            "The requested resource was not found on the server."
        case .serverBusy:
            "The server is busy with another request. Try again in a moment."
        case .cancelled:
            "The request was cancelled."
        case .invalidURL:
            "The server URL is not valid."
        case .invalidResponse:
            "The server response was not understood."
        }
    }

    init(_ underlying: Error) {
        if let mapped = underlying as? OpencodeError {
            self = mapped
            return
        }
        if Task.isCancelled || (underlying as NSError).code == NSURLErrorCancelled {
            self = .cancelled
            return
        }
        if let decodingError = underlying as? DecodingError {
            self = .decoding(String(describing: decodingError))
            return
        }
        self = .transport(underlying.localizedDescription)
    }
}
