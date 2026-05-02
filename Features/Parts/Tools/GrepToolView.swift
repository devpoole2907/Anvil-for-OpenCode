import SwiftUI

struct GrepToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if !firstResults.isEmpty {
                    ForEach(firstResults, id: \.self) { line in
                        Text(line)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Text("^[\(totalResults) result](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ToolCallDetailsView(part: part)
            }
        }
    }

    private var allLines: [String] {
        guard let output = part.state.output else { return [] }
        return output.split(whereSeparator: \.isNewline).map(String.init)
    }

    private var firstResults: [String] {
        Array(allLines.prefix(5))
    }

    private var totalResults: Int { allLines.count }
}
