import SwiftUI

struct ToolCallDetailsView: View {
    let part: ToolPart

    @State private var isPresented: Bool = false

    var body: some View {
        if hasDetails {
            Button {
                isPresented = true
            } label: {
                HStack(spacing: 4) {
                    Text("Inspect call")
                    Image(systemName: "info.circle")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isPresented) {
                ToolCallDetailsSheet(part: part)
            }
        }
    }

    private var hasDetails: Bool {
        part.callID != nil
            || part.state.time != nil
            || part.state.input != nil
            || part.state.metadata != nil
    }
}

private struct ToolCallDetailsSheet: View {
    let part: ToolPart

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        detailRow("Status", value: part.state.status)
                        if let callID = part.callID, !callID.isEmpty {
                            detailRow("Call ID", value: callID, monospaced: true)
                        }
                        if let startedAt {
                            detailRow("Started", value: startedAt)
                        }
                        if let durationText {
                            detailRow("Duration", value: durationText)
                        }
                    }

                    if let input = prettyJSON(part.state.input) {
                        rawBlock(title: "Raw Input", value: input)
                    }

                    if let metadata = prettyJSON(part.state.metadata) {
                        rawBlock(title: "Raw Metadata", value: metadata)
                    }
                }
            }
            .padding(Spacing.l)
            .navigationTitle("Tool Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
        }
    }

    private var startedAt: String? {
        part.state.time?.startDate.formatted(date: .abbreviated, time: .standard)
    }

    private var durationText: String? {
        if let duration = part.state.time?.duration {
            return duration.formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated))
        }
        if part.state.time != nil, case .running = part.state {
            return "Running"
        }
        return nil
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String, monospaced: Bool = false) -> some View {
        LabeledContent(label) {
            Text(value)
                .font(monospaced ? .caption.monospaced() : .caption)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.caption)
    }

    @ViewBuilder
    private func rawBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                Text(value)
                    .font(.caption2.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 180)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.s)
            .background(.thinMaterial)
            .clipShape(.rect(cornerRadius: Radii.small))
        }
    }

    private func prettyJSON(_ value: AnyCodable?) -> String? {
        guard let value else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value),
              let string = String(data: data, encoding: .utf8),
              !string.isEmpty
        else { return nil }
        return string
    }
}
