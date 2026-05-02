import SwiftUI

struct SessionRowView: View {
    let session: Session

    var body: some View {
        HStack(spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(session.displayTitle)
                    .bold()
                    .lineLimit(1)
                Text(session.time.updatedDate, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: Spacing.s)
        }
        .frame(minHeight: TapTarget.minimum)
        .accessibilityElement(children: .combine)
    }
}
