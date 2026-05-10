import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let source: String

    var body: some View {
        Markdown(source)
            .markdownTheme(theme)
            .textSelection(.enabled)
            .background(Color.clear)
    }

    private var theme: Theme {
        Theme.basic
            .text {
                ForegroundColor(.primary)
                BackgroundColor(nil)
            }
            .strong {
                FontWeight(.bold)
            }
            .emphasis {
                FontStyle(.italic)
            }
            .link {
                ForegroundColor(.accentColor)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(nil)
            }
            .paragraph { configuration in
                configuration.label
                    .markdownMargin(top: 0, bottom: 16)
                    .background(Color.clear)
            }
            .heading1 { configuration in
                configuration.label
                    .font(.title.bold())
                    .markdownMargin(top: 24, bottom: 16)
                    .background(Color.clear)
            }
            .heading2 { configuration in
                configuration.label
                    .font(.title2.bold())
                    .markdownMargin(top: 24, bottom: 16)
                    .background(Color.clear)
            }
            .heading3 { configuration in
                configuration.label
                    .font(.title3.bold())
                    .markdownMargin(top: 24, bottom: 16)
                    .background(Color.clear)
            }
            .codeBlock { configuration in
                configuration.label
                    .padding(Spacing.m)
                    .background(Color.clear)
                    .markdownMargin(top: 0, bottom: 16)
            }
            .table { configuration in
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 1) // Avoid clipping the bottom border
                }
                .markdownMargin(top: 8, bottom: 16)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(.em(0.85))
                        if configuration.row == 0 {
                            FontWeight(.bold)
                        }
                    }
                    .padding(.vertical, Spacing.m)
                    .padding(.horizontal, Spacing.l)
                    .overlay(
                        Rectangle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .blockquote { configuration in
                configuration.label
                    .padding(.leading, Spacing.m)
                    .background(Color.clear)
                    .markdownMargin(top: 0, bottom: 16)
            }
    }
}
