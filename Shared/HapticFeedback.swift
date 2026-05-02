import SwiftUI

/// Lightweight trigger struct that views attach to via `.sensoryFeedback(_:trigger:)`.
/// Mutating any of these counters causes the system to play the corresponding haptic.
@MainActor
@Observable
final class HapticFeedback {
    var successTrigger: Int = 0
    var warningTrigger: Int = 0
    var selectionTrigger: Int = 0
    var errorTrigger: Int = 0

    func success() { successTrigger += 1 }
    func warning() { warningTrigger += 1 }
    func selection() { selectionTrigger += 1 }
    func error() { errorTrigger += 1 }
}
