import SwiftUI

struct ProjectMenu: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Menu {
            ForEach(appModel.projectStore.projects) { project in
                Button(action: { select(project) }) {
                    if isActive(project) {
                        Label(project.displayName, systemImage: "checkmark")
                    } else {
                        Text(project.displayName)
                    }
                }
            }
            if appModel.projectStore.projects.isEmpty {
                Text("No projects available")
            }
        } label: {
            ProjectMenuLabel(name: appModel.projectStore.active?.displayName ?? "Choose project")
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityInputLabels(["Project", "Switch project"])
    }

    private var accessibilityLabel: String {
        if let active = appModel.projectStore.active {
            "Switch project, currently \(active.displayName)"
        } else {
            "Choose a project"
        }
    }

    private func isActive(_ project: Project) -> Bool {
        appModel.projectStore.active?.id == project.id
    }

    private func select(_ project: Project) {
        Task { await appModel.setActiveProject(project) }
    }
}
