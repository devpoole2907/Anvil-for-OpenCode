import SwiftUI

struct DiffView: View {
    let diff: FileDiff

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Text(diff.file)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: Spacing.s)
                DiffStatsBar(additions: diff.additions ?? 0, deletions: diff.deletions ?? 0)
            }
            DiffLinesView(lines: computedLines)
        }
        .padding(Spacing.s)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: Radii.small))
    }

    private var computedLines: [DiffLine] {
        DiffComputer.compute(before: diff.before ?? "", after: diff.after ?? "")
    }
}
