import SwiftUI

struct PermissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            List {
                if appModel.permissionStore.pending.isEmpty {
                    ContentUnavailableView(
                        "No pending permissions",
                        systemImage: "checkmark.shield",
                        description: Text("All caught up.")
                    )
                } else {
                    ForEach(appModel.permissionStore.pending) { permission in
                        PermissionRow(permission: permission, onRespond: { respond(permission, with: $0) })
                    }
                }
            }
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Dismiss")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: { dismiss() }).bold()
                }
            }
        }
    }

    private func respond(_ permission: Permission, with response: PermissionStore.PermissionResponse) {
        guard let directory = appModel.projectStore.active?.directory else { return }
        appModel.haptics.selection()
        Task {
            await appModel.permissionStore.respond(to: permission, response: response, directory: directory)
        }
    }
}

private struct PermissionRow: View {
    let permission: Permission
    var onRespond: (PermissionStore.PermissionResponse) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Label {
                Text(permission.type.capitalized).bold()
            } icon: {
                Image(systemName: icon)
            }
            if let pattern = permission.pattern, !pattern.isEmpty {
                Text(pattern)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(.rect(cornerRadius: Radii.small))
            }
            HStack(spacing: Spacing.s) {
                Button("Deny", role: .destructive) { onRespond(.deny) }
                    .buttonStyle(.bordered)
                Button("Allow Once") { onRespond(.allowOnce) }
                    .buttonStyle(.bordered)
                if isRepeatableType {
                    Button("Always Allow") { onRespond(.allowAlways) }
                        .buttonStyle(.borderedProminent)
                }
            }
            .frame(minHeight: TapTarget.minimum)
        }
        .padding(.vertical, Spacing.xs)
    }

    private var icon: String {
        switch permission.type {
        case "bash": "terminal"
        case "edit": "pencil"
        case "write": "square.and.pencil"
        case "read": "doc.text"
        default: "questionmark.shield"
        }
    }

    private var isRepeatableType: Bool {
        switch permission.type {
        case "bash", "edit", "write": true
        default: false
        }
    }
}
