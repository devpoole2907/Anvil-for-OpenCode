import SwiftUI

extension EnvironmentValues {
    /// Optional override of the active client. Most code reads the client through `AppModel`,
    /// but this is here for niche injection points (e.g. previews).
    @Entry var opencodeClient: OpencodeClient?
}
