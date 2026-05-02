import SwiftUI

struct MarkdownText: View {
    let source: String

    var body: some View {
        Text(rendered)
            .textSelection(.enabled)
    }

    private var rendered: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full
        )
        if let parsed = try? AttributedString(markdown: source, options: options) {
            return parsed
        }
        return AttributedString(source)
    }
}
