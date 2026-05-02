import Foundation

enum BasicAuth {
    /// Returns the value for the `Authorization` HTTP header, or `nil` if no password is set.
    static func header(username: String, password: String) -> String? {
        guard !password.isEmpty else { return nil }
        let raw = "\(username):\(password)"
        guard let data = raw.data(using: .utf8) else { return nil }
        return "Basic \(data.base64EncodedString())"
    }
}
