import Foundation

struct ServerProfile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var url: URL
    var username: String
    var password: String

    init(id: UUID = UUID(), name: String, url: URL, username: String, password: String) {
        self.id = id
        self.name = name
        self.url = url
        self.username = username
        self.password = password
    }
}
