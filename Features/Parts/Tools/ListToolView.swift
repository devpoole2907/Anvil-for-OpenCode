import SwiftUI

struct ListToolView: View {
    let part: ToolPart

    var body: some View {
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state) {
            if let count = entryCount {
                Text("^[\(count) entry](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var entryCount: Int? {
        guard let output = part.state.output else { return nil }
        return output.split(whereSeparator: \.isNewline).count(where: { !$0.isEmpty })
    }
}
