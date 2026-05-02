import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    @State private var showProfilePicker: Bool = false
    @State private var showModelPicker: Bool = false

    var body: some View {
        @Bindable var prefs = appModel.preferences
        NavigationStack {
            Form {
                Section("Profile") {
                    LabeledContent("Active") {
                        Text(appModel.activeProfile.name)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("URL") {
                        Text(appModel.activeProfile.url.absoluteString)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Button("Switch Profile", action: { showProfilePicker = true })
                }

                Section("Defaults") {
                    Button("Default Model", action: { showModelPicker = true })
                        .accessibilityHint("Choose the model used for new prompts")
                    Toggle("Show reasoning summaries", isOn: $prefs.showReasoning)
                }

                Section("About") {
                    LabeledContent("App Version") {
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    if let health = appModel.serverHealth {
                        LabeledContent("Server") {
                            Text("opencode \(health.version)").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: { dismiss() }).bold()
                }
            }
            .sheet(isPresented: $showProfilePicker) {
                ServerProfilePickerSheet()
            }
            .sheet(isPresented: $showModelPicker) {
                ModelPickerSheet()
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
