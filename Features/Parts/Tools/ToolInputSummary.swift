import Foundation

enum ToolInputSummary {
    static func path(from dict: [String: Any]) -> String? {
        for key in ["filePath", "path", "file", "file_path", "filepath", "target"] {
            if let value = dict[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }
}
