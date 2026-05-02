import SwiftUI

/// Container shown once an `AppModel` is ready. Owns the root navigation stack.
struct LoadedRootView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        NavigationStack {
            SessionListView()
                .navigationDestination(for: Session.self) { session in
                    ChatView(session: session)
                }
        }
        .environment(appModel)
        .sensoryFeedback(.success, trigger: appModel.haptics.successTrigger)
        .sensoryFeedback(.warning, trigger: appModel.haptics.warningTrigger)
        .sensoryFeedback(.selection, trigger: appModel.haptics.selectionTrigger)
        .sensoryFeedback(.error, trigger: appModel.haptics.errorTrigger)
    }
}
