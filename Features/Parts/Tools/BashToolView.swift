import SwiftUI

struct BashToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let command = info.subtitle {
                    Text(command)
                        .font(.callout.monospaced())
                        .padding(Spacing.s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial)
                        .clipShape(.rect(cornerRadius: Radii.small))
                        .textSelection(.enabled)
                }
                if let output = part.state.output, !output.isEmpty {
                    ScrollView {
                        Text(output)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 240)
                }
                if let errorMessage = part.state.errorMessage {
                    Label(errorMessage, systemImage: "xmark.octagon")
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
