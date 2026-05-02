import SwiftUI

struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            List {
                if appModel.providerStore.providers.isEmpty {
                    if appModel.providerStore.loading {
                        ProgressView()
                    } else {
                        ContentUnavailableView(
                            "No models available",
                            systemImage: "cpu",
                            description: Text("Configure providers in your opencode server config.")
                        )
                    }
                }
                ForEach(appModel.providerStore.providers) { provider in
                    DisclosureGroup(provider.name) {
                        ForEach(provider.models) { model in
                            let tags = provider.modelTags[model.id] ?? []
                            let displayName = tags.isEmpty ? model.displayName : "\(model.displayName) (\(tags.sorted().joined(separator: ", ")))"
                            ModelRowView(
                                model: model,
                                displayName: displayName,
                                isSelected: isSelected(provider: provider, model: model),
                                onSelect: { select(provider: provider, model: model) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Choose Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: { dismiss() }).bold()
                }
            }
        }
    }

    private func isSelected(provider: ProviderInfo, model: ModelInfo) -> Bool {
        guard let active = appModel.preferences.defaultModel(for: appModel.activeProfile.id) else {
            return false
        }
        return active.providerID == provider.id && active.modelID == model.id
    }

    private func select(provider: ProviderInfo, model: ModelInfo) {
        let ref = ModelRef(providerID: provider.id, modelID: model.id)
        appModel.preferences.setDefaultModel(ref, for: appModel.activeProfile.id)
        appModel.haptics.selection()
    }
}
