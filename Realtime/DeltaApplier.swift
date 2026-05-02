import Foundation
import OSLog

/// Applies a `MessagePartDelta` to a `Part` in place.
/// For "text" deltas on text/reasoning parts, appends to the existing text.
/// Other field/part combinations are logged at debug level and ignored.
enum DeltaApplier {
    private static let log = Logger(subsystem: "ai.opencode.client.ios", category: "DeltaApplier")

    static func apply(delta: MessagePartDelta, to part: inout Part) {
        guard delta.field == "text" else {
            log.debug("Ignoring delta on unknown field: \(delta.field, privacy: .public)")
            return
        }
        switch part {
        case .text(var text):
            text.text.append(delta.delta)
            part = .text(text)
        case .reasoning(var reasoning):
            reasoning.text.append(delta.delta)
            part = .reasoning(reasoning)
        default:
            let typeStr = part.typeString
            log.debug("Ignoring text delta on non-text part: \(typeStr, privacy: .public)")
        }
    }
}
