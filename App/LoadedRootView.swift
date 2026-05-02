import SwiftUI

struct LoadedRootView: View {
    @Bindable var appModel: AppModel
    @State private var selectedSessionID: String?
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            SessionListView(selectionID: $selectedSessionID, onCreatedSession: navigateToSession)
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
        .onChange(of: selectedSessionID) {
            preferredCompactColumn = selectedSessionID == nil ? .sidebar : .detail
        }
    }

    private var selectedSession: Session? {
        guard let selectedSessionID else { return nil }
        return appModel.sessionStore.sessions.first { $0.id == selectedSessionID }
    }

    private func navigateToSession(_ session: Session) {
        print("[Nav] navigateToSession called for session \(session.id) — '\(session.displayTitle)'")
        selectedSessionID = session.id
        preferredCompactColumn = .detail
    }
}
