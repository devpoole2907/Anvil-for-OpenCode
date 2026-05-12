import SwiftUI

struct RootView: View {
    @State private var preferences = AppPreferences()
    @State private var profileStore = ServerProfileStore()
    @State private var appModel: AppModel?
    @State private var showSetup: Bool = false

    var body: some View {
        Group {
            if let appModel {
                LoadedRootView(appModel: appModel)
            } else if showSetup {
                SetupView(onComplete: completeSetup)
            } else {
                LaunchScreenView()
            }
        }
        .task(loadInitial)
    }

    @Sendable
    private func loadInitial() async {
        let profiles = (try? profileStore.loadAll()) ?? []
        guard let profile = resolveActive(among: profiles) else {
            withAnimation {
                showSetup = true
            }
            return
        }
        let model = AppModel(profile: profile, preferences: preferences, profileStore: profileStore)
        withAnimation {
            appModel = model
        }
        await model.start()
    }

    private func resolveActive(among profiles: [ServerProfile]) -> ServerProfile? {
        if let id = preferences.activeProfileID, let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.first
    }

    private func completeSetup(_ profile: ServerProfile) {
        do {
            try profileStore.save(profile)
            preferences.activeProfileID = profile.id
            let model = AppModel(profile: profile, preferences: preferences, profileStore: profileStore)
            Task {
                await model.start()
                withAnimation {
                    appModel = model
                    showSetup = false
                }
            }
        } catch {
            // SetupView surfaces its own errors; here we silently leave the user on the form.
        }
    }
}
