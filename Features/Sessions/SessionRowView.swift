import SwiftUI

struct SessionRowView: View {
    let session: Session
    @Environment(AppModel.self) private var appModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
            if let statusLabel {
                HStack(spacing: 4) {
                    Image(systemName: statusSymbol)
                        .font(.caption2.weight(.bold))
                    Text(statusLabel)
                        .font(.caption2.weight(.semibold))
                }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .clipShape(.capsule)
            }
        }
        .frame(minHeight: TapTarget.minimum)
        .accessibilityElement(children: .combine)
    }

    private var isBusy: Bool {
        appModel.sessionStore.isSessionBusy(session.id)
    }

    private var statusLabel: String? {
        if isBusy {
            return "In Progress"
        }
        if horizontalSizeClass != .compact, appModel.activeChatID == session.id {
            return "Active"
        }
        return nil
    }

    private var statusSymbol: String {
        isBusy ? "bolt.fill" : "circle.fill"
    }

    private var statusColor: Color {
        isBusy ? .orange : .accentColor
    }
}
