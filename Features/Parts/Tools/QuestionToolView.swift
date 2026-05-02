import SwiftUI

struct QuestionToolView: View {
    let part: ToolPart

    var body: some View {
        // Pending question parts are handled by PermissionDockView; if we see one
        // outside of pending (completed/error) we render a minimal record.
        let info = ToolInfoMap.info(for: part.tool, input: part.state.input)
        BasicToolView(info: info, state: part.state) {
            if let answer = part.state.output {
                Text(answer)
                    .font(.callout)
            }
        }
    }
}
