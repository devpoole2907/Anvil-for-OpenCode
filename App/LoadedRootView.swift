import SwiftUI

struct LoadedRootView: View {
    @Bindable var appModel: AppModel
    @State private var selectedSession: Session?

    var body: some View {
        NavigationSplitView {
            SessionListView(selection: $selectedSession, onCreatedSession: navigateToSession)
        } detail: {
            if let session = selectedSession {
                ChatView(session: session)
                    .id(session.id)
            } else {
                ContentUnavailableView("Select a Session", systemImage: "message", description: Text("Choose a session from the sidebar or start a new one."))
            }
        }
        .environment(appModel)
        .sensoryFeedback(.success, trigger: appModel.haptics.successTrigger)
        .sensoryFeedback(.warning, trigger: appModel.haptics.warningTrigger)
        .sensoryFeedback(.selection, trigger: appModel.haptics.selectionTrigger)
        .sensoryFeedback(.error, trigger: appModel.haptics.errorTrigger)
    }

    private func navigateToSession(_ session: Session) {
        print("[Nav] navigateToSession called for session \(session.id) — '\(session.displayTitle)'")
        selectedSession = session
    }
}
