import SwiftUI

struct GenericToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let input = part.state.input {
                    LabeledContent("Input") {
                        Text(prettyJSON(input))
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
                if let output = part.state.output, !output.isEmpty {
                    LabeledContent("Output") {
                        Text(output)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
                if let errorMessage = part.state.errorMessage {
                    Label(errorMessage, systemImage: "xmark.octagon")
                        .foregroundStyle(.red)
                }
                ToolCallDetailsView(part: part)
            }
        }
    }

    private func prettyJSON(_ value: AnyCodable) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}
