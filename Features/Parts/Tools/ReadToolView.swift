import SwiftUI

struct ReadToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                details
                if let output = previewOutput {
                    ScrollView {
                        Text(output)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 220)
                }
                ToolCallDetailsView(part: part)
            }
        }
    }

    @ViewBuilder
    private var details: some View {
        if let input = part.state.input?.dictionaryValue {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let path = readPath(from: input) {
                    Label(path, systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let lineRange = readRange(from: input) {
                    Text(lineRange)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var previewOutput: String? {
        guard let output = part.state.output, !output.isEmpty else { return nil }
        return output
    }

    private func readPath(from dict: [String: Any]) -> String? {
        ToolInputSummary.path(from: dict)
    }

    private func readRange(from dict: [String: Any]) -> String? {
        let offset = dict["offset"] as? Int
        let limit = dict["limit"] as? Int
        if let offset, let limit {
            return "Lines \(offset)-\(offset + max(limit - 1, 0))"
        }
        if let limit {
            return "Limit \(limit)"
        }
        return nil
    }
}
