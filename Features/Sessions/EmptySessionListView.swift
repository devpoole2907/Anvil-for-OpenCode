import SwiftUI

/// Convenience wrapper around `ContentUnavailableViews.noSessions(...)`,
/// retained as a separate view per the file structure spec.
struct EmptySessionListView: View {
    var onCreate: () -> Void

    var body: some View {
        ContentUnavailableViews.noSessions(onCreate: onCreate)
    }
}
