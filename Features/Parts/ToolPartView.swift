import SwiftUI

struct ToolPartView: View {
    let part: ToolPart

    var body: some View {
        if ToolInfoMap.isHidden(part.tool) {
            EmptyView()
        } else if part.tool == "question", case .pending = part.state {
            // Question parts in pending state are surfaced via PermissionDockView.
            EmptyView()
        } else {
            switch part.tool {
            case "bash":
                BashToolView(part: part)
            case "edit":
                EditToolView(part: part)
            case "write":
                WriteToolView(part: part)
            case "read":
                ReadToolView(part: part)
            case "glob":
                GlobToolView(part: part)
            case "grep":
                GrepToolView(part: part)
            case "list":
                ListToolView(part: part)
            case "task":
                TaskToolView(part: part)
            case "question":
                QuestionToolView(part: part)
            default:
                GenericToolView(part: part)
            }
        }
    }
}
