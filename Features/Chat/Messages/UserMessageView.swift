import SwiftUI

struct UserMessageView: View {
    let turn: Turn

    var body: some View {
        HStack {
            Spacer(minLength: Spacing.xl)
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                if !text.isEmpty {
                    MarkdownText(source: text)
                        .padding(Spacing.m)
                        .background(Palette.user.opacity(0.18))
                        .clipShape(.rect(cornerRadius: Radii.large))
                }
                if !attachmentFilenames.isEmpty {
                    AttachmentSummaryView(filenames: attachmentFilenames)
                }
                if !metadataParts.isEmpty {
                    Text(metadataParts.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var text: String {
        turn.userParts
            .compactMap { part -> String? in
                if case .text(let textPart) = part { return textPart.text }
                return nil
            }
            .joined(separator: "\n\n")
    }

    private var attachmentFilenames: [String] {
        turn.userParts.compactMap { part -> String? in
            if case .file(let filePart) = part {
                return filePart.filename ?? "Attachment"
            }
            return nil
        }
    }

    private var metadataParts: [String] {
        var values: [String] = []
        for part in turn.userParts {
            if case .agent(let agent) = part {
                values.append("@\(agent.name)")
            }
        }
        if let modelID = turn.assistantMessages.first?.modelID {
            values.append(modelID)
        }
        values.append(turn.userMessage.time.createdDate.relativeShort)
        return values
    }
}

private struct AttachmentSummaryView: View {
    let filenames: [String]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "paperclip")
                .accessibilityHidden(true)
            Text(filenames.joined(separator: ", "))
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}
