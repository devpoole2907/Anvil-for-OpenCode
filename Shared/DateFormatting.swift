import Foundation

extension Date {
    /// e.g. "2 minutes ago", "yesterday", "Mar 4".
    var relativeShort: String {
        formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }

    /// e.g. "Mar 4 at 3:42 PM".
    var dayAndTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
