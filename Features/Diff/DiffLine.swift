import Foundation

struct DiffLine: Identifiable, Hashable, Sendable {
    enum Kind: Sendable { case context, addition, deletion }
    let id: UUID
    let kind: Kind
    let text: String

    init(id: UUID = UUID(), kind: Kind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }
}
