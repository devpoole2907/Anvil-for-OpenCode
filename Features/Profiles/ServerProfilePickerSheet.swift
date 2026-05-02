import SwiftUI

struct ServerProfilePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    @State private var profiles: [ServerProfile] = []
    @State private var loadError: String?
    @State private var showAdd: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Profiles") {
                    if profiles.isEmpty {
                        Text("No profiles saved.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(profiles) { profile in
                        ServerProfileRow(
                            profile: profile,
                            isActive: profile.id == appModel.activeProfile.id,
                            onSelect: { switchTo(profile) }
                        )
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                delete(profile)
                            }
                        }
                    }
                }

                Section {
                    Button("Add Profile", systemImage: "plus", action: openAdd)
                }

                if let loadError {
                    Section {
                        Label(loadError, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Servers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: { dismiss() }).bold()
                }
            }
            .sheet(isPresented: $showAdd) {
                AddProfileSheet(onAdded: handleAdded)
            }
            .task(reload)
        }
    }

    @Sendable
    private func reload() async {
        do {
            profiles = try appModel.profileStore.loadAll()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func switchTo(_ profile: ServerProfile) {
        Task {
            await appModel.switchProfile(profile)
            dismiss()
        }
    }

    private func delete(_ profile: ServerProfile) {
        guard profile.id != appModel.activeProfile.id else { return }
        do {
            try appModel.profileStore.delete(profile.id)
            profiles.removeAll { $0.id == profile.id }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func openAdd() {
        showAdd = true
    }

    private func handleAdded(_ profile: ServerProfile) {
        do {
            try appModel.profileStore.save(profile)
            profiles.append(profile)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
