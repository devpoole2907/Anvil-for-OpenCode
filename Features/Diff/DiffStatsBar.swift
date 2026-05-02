import SwiftUI

struct DiffStatsBar: View {
    let additions: Int
    let deletions: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text("+\(additions)")
                .foregroundStyle(.green)
            Text("-\(deletions)")
                .foregroundStyle(.red)
            DiffStatsBarFill(additions: additions, deletions: deletions)
                .frame(width: 36, height: 6)
        }
        .font(.caption.monospaced())
        .accessibilityLabel("\(additions) added, \(deletions) removed")
    }
}

private struct DiffStatsBarFill: View {
    let additions: Int
    let deletions: Int

    var body: some View {
        let total = max(1, additions + deletions)
        let addRatio = Double(additions) / Double(total)
        HStack(spacing: 0) {
            Rectangle().fill(.green).frame(width: 36 * addRatio)
            Rectangle().fill(.red)
        }
        .clipShape(.rect(cornerRadius: 1))
    }
}
