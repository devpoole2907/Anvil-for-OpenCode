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
        if let diff = extractedDiff {
            DiffView(diff: diff)
        } else if let errorMessage = part.state.errorMessage {
            Label(errorMessage, systemImage: "xmark.octagon")
                .foregroundStyle(.red)
        } else if let output = part.state.output, !output.isEmpty {
            Text(output)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        } else if case .running = part.state {
            ShimmerView()
        } else {
            EmptyView()
        }
    }

    private var extractedDiff: FileDiff? {
        // NOTE: opencode emits diff metadata in the tool's metadata field; shape may vary by build.
        // We try the common shape; failure is handled gracefully (text fallback).
        guard let metadata = part.state.metadata,
              let diff: FileDiff = metadata.decoded(FileDiff.self)
        else { return nil }
        return diff
    }
}
