import SwiftUI

struct EditToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state, defaultOpen: true) {
            EditToolBody(part: part)
        }
    }
}

private struct EditToolBody: View {
    let part: ToolPart

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            summary
            if let diff = extractedDiff {
            DiffView(diff: diff)
            } else if let errorMessage = part.state.errorMessage {
                Label(errorMessage, systemImage: "xmark.octagon")
                    .foregroundStyle(.red)
            } else if let output = part.state.output, !output.isEmpty {
                Text(output)
                    .font(.caption.monospaced())
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(.rect(cornerRadius: Radii.small))
                    .textSelection(.enabled)
            } else if case .running = part.state {
                ShimmerView()
            }
            ToolCallDetailsView(part: part)
        }
    }

    private var extractedDiff: FileDiff? {
        if let metadata = part.state.metadata,
           let diff: FileDiff = metadata.decoded(FileDiff.self) {
            return diff
        }
        if let metadataDict = part.state.metadata?.dictionaryValue {
            for key in ["diff", "fileDiff", "result"] {
                if let value = metadataDict[key].map(AnyCodable.init),
                   let diff: FileDiff = value.decoded(FileDiff.self) {
                    return diff
                }
            }
        }
        return nil
    }

    @ViewBuilder
    private var summary: some View {
        if let input = part.state.input?.dictionaryValue, !input.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let path = toolPath(from: input) {
                    Label(path, systemImage: "doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let oldString = input["oldString"] as? String, !oldString.isEmpty {
                    LabeledContent("Replace") {
                        Text(oldString)
                            .font(.caption2.monospaced())
                            .lineLimit(4)
                            .multilineTextAlignment(.trailing)
                    }
                }
                if let newString = input["newString"] as? String, !newString.isEmpty {
                    LabeledContent("With") {
                        Text(newString)
                            .font(.caption2.monospaced())
                            .lineLimit(4)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    private func toolPath(from dict: [String: Any]) -> String? {
        ToolInputSummary.path(from: dict)
    }
}
