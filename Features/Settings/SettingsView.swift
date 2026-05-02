import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    @State private var showProfilePicker: Bool = false

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
                    Menu {
                        ForEach(appModel.providerStore.providers) { provider in
                            Menu(provider.name) {
                                ForEach(provider.models) { model in
                                    Button {
                                        let ref = ModelRef(providerID: provider.id, modelID: model.id)
                                        withAnimation {
                                            appModel.preferences.setDefaultModel(ref, for: appModel.activeProfile.id)
                                        }
                                        appModel.haptics.selection()
                                    } label: {
                                        HStack {
                                            if appModel.isModelActive(provider: provider, model: model) {
                                                Image(systemName: "checkmark")
                                            }
                                            Text(model.displayName)
                                            let tags = provider.modelTags[model.id] ?? []
                                            if !tags.isEmpty {
                                                Text("(\(tags.sorted().joined(separator: ", ")))")
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if appModel.providerStore.providers.isEmpty {
                            Text("No models available")
                        }
                    } label: {
                        LabeledContent("Default Model") {
                            HStack(spacing: 4) {
                                Text(selectedModelNameWithTags)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
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
            .sheet(isPresented: $showProfilePicker) {
                ServerProfilePickerSheet()
            }
        }
    }

    private var selectedModelNameWithTags: String {
        guard let ref = appModel.selectedModel,
              let model = appModel.providerStore.model(matching: ref) else {
            return "No Model"
        }
        let tags = appModel.tagsForModel(providerID: ref.providerID, modelID: ref.modelID)
        if tags.isEmpty {
            return model.displayName
        } else {
            return "\(model.displayName) (\(tags.sorted().joined(separator: ", ")))"
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
