import SwiftUI

struct SetupTestStatusRow: View {
    let status: SetupModel.TestStatus

    var body: some View {
        switch status {
        case .idle:
            EmptyView()
        case .testing:
            Label {
                Text("Testing…")
            } icon: {
                ProgressView()
            }
        case .ok(let version):
            Label("Connected to opencode \(version)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }
}
