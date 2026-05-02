import Foundation

enum ToolInfoMap {
    struct Info {
        let icon: String
        let title: String
        let subtitle: String?
    }

    static func info(for tool: String, input: AnyCodable?) -> Info {
        let dict = input?.dictionaryValue ?? [:]
        switch tool {
        case "bash":
            return Info(icon: "terminal", title: "Run command", subtitle: dict["command"] as? String)
        case "edit":
            return Info(icon: "pencil", title: "Edit", subtitle: dict["path"] as? String)
        case "write":
            return Info(icon: "square.and.pencil", title: "Write", subtitle: dict["path"] as? String)
        case "read":
            return Info(icon: "doc.text", title: "Read", subtitle: dict["path"] as? String)
        case "glob":
            return Info(icon: "doc.text.magnifyingglass", title: "Glob", subtitle: dict["pattern"] as? String)
        case "grep":
            return Info(icon: "magnifyingglass", title: "Grep", subtitle: dict["pattern"] as? String)
        case "list":
            return Info(icon: "list.bullet.rectangle", title: "List", subtitle: dict["path"] as? String)
        case "task":
            return Info(icon: "person.2", title: "Sub-agent", subtitle: dict["description"] as? String)
        case "question":
            return Info(icon: "questionmark.circle", title: "Question", subtitle: dict["question"] as? String)
        case "todowrite", "todoread":
            return Info(icon: "checklist", title: "Todos", subtitle: nil)
        default:
            return Info(icon: "wrench.and.screwdriver", title: tool.capitalized, subtitle: nil)
        }
    }

    static func isContextTool(_ tool: String) -> Bool {
        switch tool {
        case "read", "glob", "grep", "list": true
        default: false
        }
    }

    static func isHidden(_ tool: String) -> Bool {
        switch tool {
        case "todowrite", "todoread": true
        default: false
        }
    }
}
