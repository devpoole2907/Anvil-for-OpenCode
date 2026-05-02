# Opencode iOS — v1 Source Drop

This zip contains the complete Swift source set for `OpencodeKit iOS v1`, generated against the OPENCODE_IOS_PLAN.md spec and reviewed against the swiftui-pro skill rules.

**Target:** iOS 26, Swift 6.2, strict concurrency.

## Layout

```
Opencode/
├── App/           App entry, AppModel, RootView
├── API/           HTTP client (actor), error types, auth
├── Realtime/      SSE event stream + DeltaApplier
├── Models/        Codable wire types (Project, Session, Message, Part, ToolState, ServerEvent, …)
├── Storage/       Keychain (ServerProfile) + UserDefaults (AppPreferences)
├── State/         @MainActor @Observable stores (Project/Session/Chat/Provider/Permission)
├── Shared/        DesignTokens, MarkdownText, Shimmer, Haptics, etc.
├── Features/
│   ├── Setup/     First-run server setup
│   ├── Profiles/  Profile picker + add
│   ├── Projects/  Toolbar project menu
│   ├── Sessions/  Session list
│   ├── Chat/      ChatView + composer + docks + Messages/
│   ├── Parts/     Part dispatch + Tools/ subviews
│   ├── Diff/      LCS diff renderer
│   ├── Models/    Model picker
│   └── Settings/  Settings + ProfileEditView
└── Tests/         Swift Testing suites (Codable, deltas, events, endpoints, tool map)
```

## Notes for the downstream agentic coder

1. **Drop the contents** of `Opencode/` into the iOS app target's source root. Tests go in the test target.
2. **Bundle ID placeholder:** `ai.opencode.client.ios` (used as the Keychain service identifier in `ServerProfileStore`). The user may suggest a new bundle ID instead of this one.
3. **`OpencodeApp.swift`** is `@main`. Remove any pre-existing `@main` entry point from the Xcode template.
4. The `sendPrompt` method in `OpencodeClient` POSTs to `/session/{id}/prompt`. Per §A of the plan, if the user's running server uses `/session/{id}/message` instead, adjust that one method — SSE drives the UI either way.
5. Photo attachments: `AttachmentPickerSheet` ships the picker UI; the conversion of `PhotosPickerItem` → `PromptPart.file(...)` data URI is wired up to the chat send path as a v1 polish item (noted with `// NOTE:` in the file).
6. Auto-scroll in `MessageTimelineView` always pins to the bottom; the "user has manually scrolled" detection is a polish item flagged in-source.
7. All `// NOTE:` comments mark places where reasonable choices were made under spec ambiguity.

## What's deliberately not here (per §16)

Terminal panel, file tree, full settings UI, session forking/sharing, LSP, search, i18n, mDNS auto-discovery, push notifications, iCloud profile sync, onboarding tour, crash reporting.
