import SwiftUI

struct TextPartView: View {
    let part: TextPart

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            MarkdownText(source: part.text)
            HStack {
                Spacer()
                CopyButton(text: part.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
