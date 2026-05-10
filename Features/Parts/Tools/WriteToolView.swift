import SwiftUI

struct WriteToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state, defaultOpen: true) {
            WriteToolBody(part: part)
        }
    }
}

private struct WriteToolBody: View {
    let part: ToolPart

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let diff = extractedDiff {
                DiffView(diff: diff)
            } else if let errorMessage = part.state.errorMessage {
                Label(errorMessage, systemImage: "xmark.octagon")
                    .foregroundStyle(.red)
            } else if let preview {
                ScrollView {
                    Text(preview)
                        .font(.caption.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 240)
            }
            ToolCallDetailsView(part: part)
        }
    }

    private var extractedDiff: FileDiff? {
        part.state.metadata?.decoded(FileDiff.self)
    }

    private var preview: String? {
        guard let dict = part.state.input?.dictionaryValue else { return nil }
        return dict["content"] as? String
    }
}
