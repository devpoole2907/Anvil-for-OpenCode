import SwiftUI

struct SetupView: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (ServerProfile) -> Void

    @State private var model = SetupModel()
    @FocusState private var focused: Field?

    private enum Field: Hashable { case name, url, username, password }

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Name", text: $model.name)
                        .focused($focused, equals: .name)
                        .textContentType(.organizationName)

                    TextField("URL", text: $model.urlText, prompt: Text(verbatim: "https://opencode.local:4096"))
                        .focused($focused, equals: .url)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                Section("Authentication") {
                    TextField("Username", text: $model.username)
                        .focused($focused, equals: .username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $model.password)
                        .focused($focused, equals: .password)
                        .textContentType(.password)
                }

                Section {
                    Button("Test Connection", action: runTest)
                        .disabled(model.parsedURL == nil)
                    SetupTestStatusRow(status: model.testStatus)
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Dismiss")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .disabled(!model.canSubmit)
                        .bold()
                }
            }
        }
    }

    private func runTest() {
        Task { await model.test() }
    }

    private func save() {
        guard let profile = model.build() else { return }
        onComplete(profile)
    }
}
