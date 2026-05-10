import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    var profile: ServerProfile
    var onSave: (ServerProfile) -> Void

    @State private var name: String
    @State private var urlText: String
    @State private var username: String
    @State private var password: String

    init(profile: ServerProfile, onSave: @escaping (ServerProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _name = State(initialValue: profile.name)
        _urlText = State(initialValue: profile.url.absoluteString)
        _username = State(initialValue: profile.username)
        _password = State(initialValue: profile.password)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Name", text: $name)
                    TextField("URL", text: $urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                Section("Authentication") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                }
            }
            .navigationTitle("Edit Profile")
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
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.isEmpty && URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) != nil && !username.isEmpty
    }

    private func save() {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        let updated = ServerProfile(
            id: profile.id,
            name: name,
            url: url,
            username: username,
            password: password
        )
        onSave(updated)
        dismiss()
    }
}
