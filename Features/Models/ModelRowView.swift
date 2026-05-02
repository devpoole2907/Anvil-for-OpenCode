import SwiftUI

struct ModelRowView: View {
    let model: ModelInfo
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(model.displayName).bold()
                    if let detail = subtitleText {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: Spacing.s)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityLabel("Selected")
                }
            }
            .frame(minHeight: TapTarget.minimum)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var subtitleText: String? {
        var pieces: [String] = []
        if let input = model.cost?.input, let output = model.cost?.output {
            let inputFormatted = input.formatted(.number.precision(.fractionLength(0...2)))
            let outputFormatted = output.formatted(.number.precision(.fractionLength(0...2)))
            pieces.append("$\(inputFormatted) / $\(outputFormatted) per 1M")
        }
        return pieces.isEmpty ? nil : pieces.joined(separator: " · ")
    }
}
