import Foundation

enum ToolInfoMap {
    struct Info {
        let icon: String
        let title: String
        let subtitle: String?
    }

    private static func extractPath(from dict: [String: Any]) -> String? {
        let stringKeys = ["path", "file", "file_path", "filepath", "absolute_path", "absolutePath", "relative_path", "relativePath", "target"]
        for key in stringKeys {
            if let str = dict[key] as? String {
                return str
            }
        }
        
        let arrayKeys = ["paths", "files", "filepaths", "filePaths", "absolute_paths", "relative_paths"]
        for key in arrayKeys {
            if let array = dict[key] as? [Any], let first = array.first as? String {
                if array.count > 1 {
                    return "\(first) (+\(array.count - 1) more)"
                }
                return first
            }
        }
        return nil
    }

    private static func filename(from path: String?) -> String? {
        guard let path = path, !path.isEmpty else { return nil }
        // Strip trailing annotation like " (+N more)"
        let pathWithoutAnnotation: String
        if let annotationIndex = path.range(of: " (+")?.lowerBound {
            // Verify it matches the pattern " (+<digits> more)"
            let suffix = String(path[annotationIndex...])
            let pattern = #"^ \(\+\d+ more\)$"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: suffix, range: NSRange(suffix.startIndex..., in: suffix)) != nil {
                pathWithoutAnnotation = String(path[..<annotationIndex])
            } else {
                pathWithoutAnnotation = path
            }
        } else {
            pathWithoutAnnotation = path
        }
        // Extract the last path component using URL
        let component = URL(fileURLWithPath: pathWithoutAnnotation).lastPathComponent
        return component.isEmpty ? nil : component
    }

    static func info(for tool: String, input: AnyCodable?) -> Info {
        let dict = input?.dictionaryValue ?? [:]
        switch tool {
        case "bash":
            return Info(icon: "terminal", title: "Run command", subtitle: dict["command"] as? String)
        case "edit":
            let path = extractPath(from: dict)
            let name = filename(from: path)
            return Info(icon: "pencil", title: name != nil ? "Edit \(name!)" : "Edit", subtitle: path)
        case "write":
            let path = extractPath(from: dict)
            let name = filename(from: path)
            return Info(icon: "square.and.pencil", title: name != nil ? "Write \(name!)" : "Write", subtitle: path)
        case "read":
            let path = extractPath(from: dict)
            let name = filename(from: path)
            return Info(icon: "doc.text", title: name != nil ? "Read \(name!)" : "Read", subtitle: path)
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
