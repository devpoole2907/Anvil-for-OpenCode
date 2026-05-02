# OpencodeKit iOS — v1 Implementation Plan

**This document is a prompt.** It is intended to be pasted into a fresh Claude.ai chat (Opus, with no prior context) so that Claude can generate the complete set of Swift source files for an iOS 26 client of [opencode](https://github.com/anomalyco/opencode). The output of that chat will be handed to a second agent (opencode itself, running DeepSeek or GLM) to assemble into a working Xcode project.

You (the Claude reading this) should produce **every Swift file specified** under "Per-File Specifications" below. Adhere strictly to the architectural decisions, code-style rules, and output format. Do not improvise file structure, do not skip files, do not add new dependencies, do not ask clarifying questions before producing output — if something is genuinely ambiguous, make a reasonable choice and add a `// NOTE:` comment in the affected file.

---

## 1. Mission

Build an iOS-native client for opencode — an open-source AI coding agent with a client/server architecture. The user already runs `opencode serve` on a Mac/Linux box (homelab, dev machine, Tailscale-reachable). This iOS app connects over HTTP, lets the user resume sessions, send prompts, watch agentic tool use stream in real time, approve permission requests, and review file diffs from the phone.

**Audience: a power user developer.** The user is technical, runs their own server, and values:
- A faithful representation of opencode's session/turn/part model
- Real-time streaming (token-level via SSE delta events)
- Clean Swift 6.2 code under strict concurrency
- iOS-native feel — Liquid Glass, haptics, Dynamic Type, VoiceOver

This is **v1**. It does *not* implement: terminal panel, file tree browsing/editing, full settings UI for keybinds/themes/providers/MCP, session forking/sharing, LSP diagnostics, search, i18n. Those are explicitly deferred. The v1 set is large enough on its own.

---

## 2. Background: What is Opencode

(For context only — you don't need to reproduce this anywhere in the code.)

Opencode is a Bun/TypeScript HTTP server (`opencode serve`) that exposes 200+ REST endpoints plus SSE event streams. It manages multi-project, multi-workspace AI coding sessions. Users prompt the agent; the agent runs tools (`bash`, `read`, `write`, `edit`, `grep`, `glob`, `list`, `task`, `question`); each tool call may need user permission; results stream back as message parts.

**Architecture:**
- **Multi-project:** every API call carries a `directory` query parameter (the project root). The server has a notion of "current project" but clients pass directory explicitly.
- **Sessions:** scoped to a project. Each session has a list of messages.
- **Messages:** either `user` or `assistant`. Each has an array of typed `parts`.
- **Parts:** discriminated by `type` — `text`, `reasoning`, `tool`, `compaction`, `file`, `agent`. Tool parts carry a `state` object that transitions from `pending` → `running` → `completed`/`error`.
- **Streaming:** the server publishes events on the bus; SSE delivers them at `/global/event`. The big ones are `message.part.updated` (full part replacement) and `message.part.delta` (streaming delta on a field, typically `text`).
- **Auth:** optional HTTP Basic via `OPENCODE_SERVER_PASSWORD` (username defaults to `opencode`).

The official JS SDK is at `@opencode-ai/sdk`; the OpenAPI spec lives at `packages/sdk/openapi.json` in the repo. We are **not** generating from OpenAPI — we are hand-rolling a focused subset.

---

## 3. Locked-in Architectural Decisions

These are decided. Do not deviate.

1. **iOS 26 only.** Use the latest SwiftUI and Swift 6.2.
2. **Pure SwiftUI.** No UIKit unless wrapping an irreducible primitive (none expected for v1).
3. **No third-party packages.** Markdown rendering uses `AttributedString(markdown:)`. SSE is hand-parsed via `URLSession.bytes(for:)`. Keychain is hit through `Security` framework directly.
4. **Single iOS app target.** No separate Swift package. All code lives in the app target. (We deliberately rejected an `OpencodeKit` SwiftPM package — it's overkill for one client.)
5. **`@Observable` + `@MainActor` everywhere.** All view-bound state classes are `@MainActor @Observable`. Networking is on an `actor` (`OpencodeClient`); state classes call into it via `await`.
6. **Strict concurrency.** Assume Swift 6 strict concurrency. No `DispatchQueue`. No `Task.detached` unless justified with a comment.
7. **Multi-project at the data layer.** The server requires it. UI exposes it as a **toolbar title menu** at the top of the session list and chat screens, listing available projects with a checkmark on the active one. No sidebar. No `NavigationSplitView`.
8. **Multi-profile server config.** From day one. The user has more than one server (dev Mac, homelab box) and switches. Stored in Keychain, picked from a sheet.
9. **Streaming via `/global/event`** filtered to the active project's directory. Delta events are applied incrementally to existing parts in `ChatStore`.
10. **Permission flow is non-blocking.** When `permission.updated` arrives, surface a sheet (or dock) with Allow/Deny/Allow Always; user choice is POSTed back. The chat continues underneath.
11. **No SwiftData, no Core Data.** Server is the source of truth. The only persistence is Keychain (server profiles) and `UserDefaults` (small prefs like default model). Chat state is in-memory; lost on app relaunch (the next session load re-fetches from server).
12. **Codenames:** Project: `OpencodeKit`. App target: `Opencode`. Bundle ID placeholder: `ai.opencode.client.ios`.
13. **NavigationStack only.** No NavigationSplitView. Push semantics for project → session list → chat are NOT used; sessions are presented modally or pushed one level deep from the session list. See navigation map below.

---

## 4. Tech Stack & Dependencies

- Swift 6.2
- SwiftUI (iOS 26)
- Foundation, URLSession (built-in)
- Security framework (Keychain)
- WebKit (only if you must — not expected for v1)
- That's it.

Do **not** add: Alamofire, SwiftMarkdown, SwiftKeychainWrapper, swift-openapi-generator, or any other dependency. If you find yourself wanting one, write the small piece by hand instead.

---

## 5. Project & Folder Structure

```
Opencode/
├── App/
│   ├── OpencodeApp.swift
│   ├── RootView.swift
│   └── AppModel.swift
├── API/
│   ├── OpencodeClient.swift
│   ├── OpencodeError.swift
│   ├── HTTPMethod.swift
│   └── BasicAuth.swift
├── Realtime/
│   ├── EventStream.swift
│   └── DeltaApplier.swift
├── Models/
│   ├── Project.swift
│   ├── Session.swift
│   ├── Message.swift
│   ├── Part.swift
│   ├── TextPart.swift
│   ├── ReasoningPart.swift
│   ├── CompactionPart.swift
│   ├── ToolPart.swift
│   ├── ToolState.swift
│   ├── FilePart.swift
│   ├── AgentPart.swift
│   ├── PromptBody.swift
│   ├── Provider.swift
│   ├── ProviderInfo.swift
│   ├── ModelInfo.swift
│   ├── ConfigInfo.swift
│   ├── HealthInfo.swift
│   ├── Permission.swift
│   ├── Todo.swift
│   ├── FileDiff.swift
│   ├── Turn.swift
│   └── ServerEvent.swift
├── Storage/
│   ├── ServerProfile.swift
│   ├── ServerProfileStore.swift
│   └── AppPreferences.swift
├── State/
│   ├── ProjectStore.swift
│   ├── SessionStore.swift
│   ├── ChatStore.swift
│   ├── ProviderStore.swift
│   └── PermissionStore.swift
├── Features/
│   ├── Setup/
│   │   ├── SetupView.swift
│   │   └── SetupModel.swift
│   ├── Profiles/
│   │   ├── ServerProfilePickerSheet.swift
│   │   └── AddProfileSheet.swift
│   ├── Projects/
│   │   ├── ProjectMenu.swift
│   │   └── ProjectMenuLabel.swift
│   ├── Sessions/
│   │   ├── SessionListView.swift
│   │   ├── SessionRowView.swift
│   │   └── EmptySessionListView.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   ├── ChatToolbar.swift
│   │   ├── ChatComposer.swift
│   │   ├── AttachmentPickerSheet.swift
│   │   ├── TodoDockView.swift
│   │   ├── PermissionDockView.swift
│   │   ├── PermissionSheet.swift
│   │   └── Messages/
│   │       ├── MessageTimelineView.swift
│   │       ├── TurnView.swift
│   │       ├── UserMessageView.swift
│   │       ├── AssistantMessageView.swift
│   │       └── ThinkingIndicatorView.swift
│   ├── Parts/
│   │   ├── TextPartView.swift
│   │   ├── ReasoningPartView.swift
│   │   ├── CompactionPartView.swift
│   │   ├── ToolPartView.swift
│   │   ├── ToolInfoMap.swift
│   │   ├── BasicToolView.swift
│   │   ├── ContextToolGroupView.swift
│   │   ├── GenericToolView.swift
│   │   └── Tools/
│   │       ├── BashToolView.swift
│   │       ├── EditToolView.swift
│   │       ├── WriteToolView.swift
│   │       ├── ReadToolView.swift
│   │       ├── GlobToolView.swift
│   │       ├── GrepToolView.swift
│   │       ├── ListToolView.swift
│   │       ├── TaskToolView.swift
│   │       └── QuestionToolView.swift
│   ├── Diff/
│   │   ├── DiffView.swift
│   │   └── DiffStatsBar.swift
│   ├── Models/
│   │   ├── ModelPickerSheet.swift
│   │   └── ModelRowView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── ProfileEditView.swift
├── Shared/
│   ├── DesignTokens.swift
│   ├── MarkdownText.swift
│   ├── CopyButton.swift
│   ├── ShimmerView.swift
│   ├── CollapsibleSection.swift
│   ├── ContentUnavailableViews.swift
│   ├── DateFormatting.swift
│   ├── HapticFeedback.swift
│   └── EnvironmentKeys.swift
└── Tests/ (in OpencodeTests target)
    ├── PartCodingTests.swift
    ├── DeltaApplierTests.swift
    ├── ServerEventDecodingTests.swift
    ├── EndpointBuilderTests.swift
    └── ToolInfoMapTests.swift
```

**Rules about file structure:**
- Exactly one type per file (struct, class, enum). Small private helper structs may live in the same file *only* when they are tightly coupled and not reused (e.g. a private `_Row` helper inside `ToolPartView.swift`).
- File name matches the primary type name.
- Group folders by feature, not by type. (i.e. `Features/Chat/` not `Views/`.)

---

## 6. Code Style Rules

**These are non-negotiable.** They derive from the swiftui-pro skill (Paul Hudson). Do not skip any.

### Modern API
- `foregroundStyle(...)`, never `foregroundColor(...)`.
- `clipShape(.rect(cornerRadius:))`, never `cornerRadius(...)`.
- `Tab(...)` API, never `tabItem(...)`.
- `onChange(of:)` 0- or 2-parameter form only (never the deprecated 1-param form).
- Avoid `GeometryReader` if any modern alternative works (`containerRelativeFrame`, `visualEffect`, `Layout`).
- `sensoryFeedback(...)` for haptics, never `UIImpactFeedbackGenerator`.
- `@Entry` macro for environment values.
- `overlay(alignment:content:)` not `overlay(_:alignment:)`.
- Toolbar placements `.topBarLeading` / `.topBarTrailing`, never `.navigationBarLeading` / `.navigationBarTrailing`.
- Shapes: chain `.fill().stroke()`, no overlay needed (iOS 17+).
- `.scrollIndicators(.hidden)` not `showsIndicators: false`.
- No `Text + Text` concatenation — use interpolation with formatted `Text`.
- iOS 26 native `WebView` (don't wrap WKWebView) — but v1 doesn't need it.

### Swift Language
- Prefer Swift-native: `replacing(_:with:)` not `replacingOccurrences(of:with:)`.
- Modern Foundation: `URL.documentsDirectory`, `appending(path:)`.
- Never `String(format:)`. Use `Text(value, format: .number.precision(.fractionLength(2)))` and friends.
- Static member lookup: `.circle` not `Circle()`, `.borderedProminent` not `BorderedProminentButtonStyle()`.
- No force unwraps `!` or `try!`. Prefer `if let value {` shorthand.
- Filter on user input with `localizedStandardContains`.
- `Double` over `CGFloat`.
- `count(where:)` not `filter { ... }.count`.
- `Date.now` not `Date()`.
- Conform sortable types to `Comparable` rather than repeating sort closures.
- `if let value {` shorthand.
- Single-expression functions: omit `return`. `if`/`switch` as expressions when assigning.

### Concurrency
- `async`/`await` over closures.
- No `DispatchQueue.*`. Use `Task`, `actor`, `@MainActor`.
- `Task.sleep(for:)` not `Task.sleep(nanoseconds:)`.
- No `Task.detached` without a comment justifying it.
- Mutable shared state must be in an `actor` or `@MainActor`-isolated.
- Don't add `MainActor.run { ... }` if the calling context is already `@MainActor`.

### View Construction
- **Extract subviews into separate `View` structs.** Do not break a body up with computed properties returning `some View`. (Yes, even `@ViewBuilder` ones. Yes, this matters.)
- Long bodies → break into structs.
- Button actions live in methods, not inline closures.
- Logic out of `body`, `task`, `onAppear` — into view models or stores.
- One type per file.
- `TextField` with `axis: .vertical`, `lineLimit(5...)` over `TextEditor` for chat input.
- `Button("Label", systemImage: "x", action: foo)` form.
- `#Preview` not `PreviewProvider`.
- `TabView(selection:)` bound to an enum, not Int/String (we don't have a TabView in v1, but stick to the rule).
- `@Animatable` macro over manual `Animatable` conformance.
- `withAnimation { ... } completion: { withAnimation { ... } }` for chained animations.
- `.animation(_:value:)` always specifies a value.

### Data Flow
- `@Observable` classes are `@MainActor`.
- Local view state with `@State` is `private`.
- Shared state: `@Observable` class held by `@State` somewhere, passed via `@Bindable` or `@Environment`.
- No `@AppStorage` inside `@Observable` classes (it won't trigger updates).
- Bindings: never `Binding(get:set:)` in body. Use `@State` + `onChange` or expose computed bindings on the model.
- Numeric `TextField`: bind to the number, use `format: .number`, plus `.keyboardType(...)`.

### Navigation
- `NavigationStack` only (no `NavigationView`).
- `navigationDestination(for:)` for destinations. Never `NavigationLink(destination:)`.
- One destination registration per type per stack.
- `confirmationDialog` attached to its trigger.
- Single-OK alert: omit the button — `.alert("Title", isPresented: $flag) { }`.
- `sheet(item:)` for optional-driven sheets. `sheet(item: $foo, content: SomeView.init)` form when the view's only init param is the item.

### Performance
- Ternary not if/else for modifier toggles (`.foregroundStyle(isOn ? .green : .gray)`).
- No `AnyView`.
- `LazyVStack`/`LazyHStack` for any list with potentially > ~30 items.
- Move work to `task()`, not init.
- `body` runs often — no work inside.
- No `DateFormatter` properties; use `Text(date, format: ...)`.
- `task()` not `onAppear()` for async work.
- For `@ViewBuilder` content properties, store the built value (`@ViewBuilder let content: Content`), not a closure.

### Design
- **Centralize design tokens** in `DesignTokens.swift` (an enum). Use them. Don't sprinkle magic numbers.
- No `UIScreen.main.bounds`.
- Avoid fixed frames; flexible by default.
- 44×44 minimum tap targets.
- `ContentUnavailableView` for empty/error states.
- `Label` over `HStack` for icon + text.
- Hierarchical styles (`.secondary`, `.tertiary`) not opacity tweaking.
- `LabeledContent` in forms.
- `bold()` over `fontWeight(.bold)`.
- Avoid `.caption2`. Use `.caption` carefully.
- No `UIColor` in SwiftUI; use `Color`.

### Accessibility
- Dynamic Type — never hard-code font sizes. If you must scale, use `.font(.body.scaled(by:))` (iOS 26 native).
- Decorative images: `Image(decorative:)` or `accessibilityHidden(true)`.
- Reduce Motion: large animated transitions degrade to opacity (use `@Environment(\.accessibilityReduceMotion)`).
- Buttons must always have a text label, even if visually hidden via `.labelStyle(.iconOnly)`.
- Don't use `onTapGesture` for ordinary buttons. If you must (e.g. tap location matters), add `.accessibilityAddTraits(.isButton)`.
- Frequently changing labels (status pills, model name): add `accessibilityInputLabels(...)` for Voice Control.
- `accessibilityDifferentiateWithoutColor` — use icons/strokes alongside any color-only signal.

### Hygiene
- No secrets in repo. The Keychain wrapper handles user-provided credentials.
- Comment non-obvious logic. Skip comments for self-evident code.
- Tests for: Codable round-tripping of Parts/Events, delta application, endpoint URL building.
- Keychain (not `@AppStorage`) for username/password.

---

## 7. Design System

`DesignTokens.swift` defines:

```swift
enum Spacing {
    static let xs: Double = 4
    static let s: Double = 8
    static let m: Double = 12
    static let l: Double = 16
    static let xl: Double = 24
    static let xxl: Double = 32
}

enum Radii {
    static let small: Double = 6
    static let medium: Double = 10
    static let large: Double = 16
}

enum AnimationDurations {
    static let quick: Duration = .milliseconds(150)
    static let standard: Duration = .milliseconds(250)
}

enum Palette {
    // SwiftUI-native semantic colors only — wrappers for clarity
    static let user: Color = .accentColor
    static let assistant: Color = .primary
    static let toolPending: Color = .orange
    static let toolError: Color = .red
}
```

Use these. Do not hard-code spacing values.

Liquid Glass is enabled by default in iOS 26 — use `.background(.regularMaterial)` and `.glassEffect()` (where applicable) for elevated surfaces. Don't fight the system look.

---

## 8. Data Model (Codable Types)

These mirror opencode's `types.gen.ts` but trimmed to v1 needs. Use `snake_case` decoding with `convertFromSnakeCase` ONLY where the server sends snake_case; opencode mostly uses camelCase, so default Codable should work. Verify on first integration test.

### `Project`
```swift
struct Project: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let directory: String   // absolute path on server
    let name: String?       // optional friendly name
    let worktree: String?
    let time: TimeRange
}

struct TimeRange: Codable, Hashable, Sendable {
    let created: Double
    let updated: Double
}
```

### `Session`
```swift
struct Session: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var title: String?
    let parentID: String?
    let projectID: String?
    let directory: String?
    let time: TimeRange
    let revert: SessionRevertInfo?     // present if reverted
    let share: SessionShareInfo?       // ignore for v1
}

struct SessionRevertInfo: Codable, Hashable, Sendable {
    let messageID: String
    let partID: String?
}

struct SessionShareInfo: Codable, Hashable, Sendable {
    let url: String
}
```

### `Message`
```swift
enum Message: Codable, Identifiable, Hashable, Sendable {
    case user(UserMessage)
    case assistant(AssistantMessage)
    
    var id: String { switch self { case .user(let m): m.id; case .assistant(let m): m.id } }
    var sessionID: String { ... }
    var time: MessageTime { ... }
    
    private enum CodingKeys: String, CodingKey { case role }
    init(from decoder: Decoder) throws { /* peek role, decode appropriate */ }
    func encode(to encoder: Encoder) throws { /* delegate */ }
}

struct UserMessage: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let role: String        // always "user"
    let sessionID: String
    let time: MessageTime
}

struct AssistantMessage: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let role: String        // always "assistant"
    let sessionID: String
    let parentID: String?   // ID of the user message that started this turn
    let providerID: String?
    let modelID: String?
    let time: MessageTime
    let cost: Double?
    let tokens: TokenUsage?
    let summary: AssistantSummary?
    let error: AssistantError?
}

struct MessageTime: Codable, Hashable, Sendable {
    let created: Double
    let completed: Double?
}

struct TokenUsage: Codable, Hashable, Sendable {
    let input: Int?
    let output: Int?
    let reasoning: Int?
    let cache: CacheTokens?
}

struct CacheTokens: Codable, Hashable, Sendable {
    let read: Int?
    let write: Int?
}

struct AssistantSummary: Codable, Hashable, Sendable {
    let diffs: [FileDiff]?
}

struct AssistantError: Codable, Hashable, Sendable {
    let name: String
    let data: AnyCodable?    // see AnyCodable note below
}
```

### `Part`
A discriminated union. Use this exact pattern:

```swift
enum Part: Codable, Identifiable, Hashable, Sendable {
    case text(TextPart)
    case reasoning(ReasoningPart)
    case tool(ToolPart)
    case compaction(CompactionPart)
    case file(FilePart)
    case agent(AgentPart)
    case unknown(type: String, id: String, raw: AnyCodable)
    
    var id: String { ... }
    var sessionID: String { ... }
    var messageID: String { ... }
    
    private enum CodingKeys: String, CodingKey { case type }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "text": self = .text(try TextPart(from: decoder))
        case "reasoning": self = .reasoning(try ReasoningPart(from: decoder))
        case "tool": self = .tool(try ToolPart(from: decoder))
        case "step-start", "step-finish": 
            // skip these by treating as unknown — UI doesn't render them
            self = .unknown(type: type, id: "step-\(UUID().uuidString)", raw: AnyCodable.null)
        case "compaction": self = .compaction(try CompactionPart(from: decoder))
        case "file": self = .file(try FilePart(from: decoder))
        case "agent": self = .agent(try AgentPart(from: decoder))
        default:
            let raw = try AnyCodable(from: decoder)
            let id = (try? c.decode(String.self, forKey: .init(stringValue: "id")!)) ?? "unknown-\(UUID())"
            self = .unknown(type: type, id: id, raw: raw)
        }
    }
    
    func encode(to encoder: Encoder) throws { /* dispatch */ }
}
```

Each part struct (`TextPart`, `ReasoningPart`, etc.) gets its own file:

```swift
struct TextPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String           // "text"
    var text: String           // mutable so deltas can append
    var time: PartTime?
    var synthetic: Bool?       // synthetic parts not shown in user message body
}

struct ReasoningPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String           // "reasoning"
    var text: String
    var time: PartTime?
}

struct ToolPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String           // "tool"
    let tool: String           // "bash", "edit", "read", etc.
    var state: ToolState
    let callID: String?
}

enum ToolState: Codable, Hashable, Sendable {
    case pending(ToolStatePending)
    case running(ToolStateRunning)
    case completed(ToolStateCompleted)
    case error(ToolStateError)
    
    private enum CodingKeys: String, CodingKey { case status }
    init(from: Decoder) throws { /* dispatch on status field */ }
    func encode(to: Encoder) throws { /* */ }
    
    var status: String { ... }
}

struct ToolStatePending: Codable, Hashable, Sendable {
    let status: String         // "pending"
}

struct ToolStateRunning: Codable, Hashable, Sendable {
    let status: String         // "running"
    var input: AnyCodable?
    var time: ToolTime?
}

struct ToolStateCompleted: Codable, Hashable, Sendable {
    let status: String         // "completed"
    let input: AnyCodable
    let output: String?
    let title: String?
    let metadata: AnyCodable?
    let time: ToolTime?
}

struct ToolStateError: Codable, Hashable, Sendable {
    let status: String         // "error"
    let error: String
    let input: AnyCodable?
    let time: ToolTime?
}

struct ToolTime: Codable, Hashable, Sendable {
    let start: Double
    let end: Double?
}

struct CompactionPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String           // "compaction"
    let time: PartTime?
}

struct FilePart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String           // "file"
    let mediaType: String?
    let filename: String?
    let url: String?           // server URL or data URI
    let source: FilePartSource?
}

struct FilePartSource: Codable, Hashable, Sendable {
    let path: String?
    let text: FileSourceTextRange?
}

struct FileSourceTextRange: Codable, Hashable, Sendable {
    let start: Int
    let end: Int
    let value: String?
}

struct AgentPart: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String           // "agent"
    let name: String
    let source: AgentPartSource?
}

struct AgentPartSource: Codable, Hashable, Sendable {
    let start: Int
    let end: Int
    let value: String?
}

struct PartTime: Codable, Hashable, Sendable {
    let start: Double?
    let end: Double?
}
```

### `AnyCodable`
A type-erased Codable wrapper. Implement the standard pattern: an enum or struct that wraps `Any` and implements Codable for all JSON-compatible primitives plus arrays/objects. Many tool inputs/outputs are arbitrary JSON; we don't parse them strictly. Provide `func decoded<T: Decodable>(_:)` for cases where view code wants to extract a known shape.

Place in `Models/AnyCodable.swift` (add this file to the structure).

### `Turn`
Computed grouping (not from server):

```swift
struct Turn: Identifiable, Hashable {
    let userMessage: UserMessage
    let assistantMessages: [AssistantMessage]
    let userParts: [Part]
    let assistantParts: [Part]
    
    var id: String { userMessage.id }
}
```

`ChatStore` derives `[Turn]` from the flat message/part lists.

### `ServerEvent`
```swift
enum ServerEvent: Decodable, Sendable {
    case sessionUpdated(Session)
    case sessionDeleted(sessionID: String)
    case messageUpdated(Message)
    case messageRemoved(sessionID: String, messageID: String)
    case messagePartUpdated(Part)
    case messagePartDelta(MessagePartDelta)
    case messagePartRemoved(sessionID: String, messageID: String, partID: String)
    case permissionUpdated(Permission)
    case permissionReplied(permissionID: String)
    case serverConnected
    case ignored(type: String)
    
    private enum CodingKeys: String, CodingKey { case type, properties }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "session.updated":
            let p = try c.decode(SessionUpdatedPayload.self, forKey: .properties)
            self = .sessionUpdated(p.info)
        // ... and so on
        default: self = .ignored(type: type)
        }
    }
}

struct MessagePartDelta: Decodable, Sendable {
    let sessionID: String
    let messageID: String
    let partID: String
    let field: String     // e.g. "text"
    let delta: String
}
```

### `Permission`, `Todo`, `FileDiff`
```swift
struct Permission: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String?
    let callID: String?
    let type: String          // "bash", "edit", "write", etc.
    let pattern: String?
    let metadata: AnyCodable?
    let time: PermissionTime
}

struct PermissionTime: Codable, Hashable, Sendable {
    let created: Double
}

struct Todo: Codable, Identifiable, Hashable, Sendable {
    var id: String { content }
    let content: String
    let status: String        // "pending", "in_progress", "completed"
    let priority: String?
}

struct FileDiff: Codable, Identifiable, Hashable, Sendable {
    var id: String { file }
    let file: String
    let before: String?
    let after: String?
    let additions: Int?
    let deletions: Int?
}
```

### `Provider`, `ProviderInfo`, `ModelInfo`
```swift
struct ProviderListResponse: Codable, Sendable {
    let providers: [ProviderInfo]
    let `default`: [String: String]   // providerID → default modelID
}

struct ProviderInfo: Codable, Identifiable, Hashable, Sendable {
    var id: String { providerID }
    let providerID: String
    let name: String
    let models: [ModelInfo]
}

struct ModelInfo: Codable, Identifiable, Hashable, Sendable {
    var id: String { modelID }
    let modelID: String
    let name: String?
    let costInput: Double?
    let costOutput: Double?
    let contextLimit: Int?
    let outputLimit: Int?
}

struct ModelRef: Codable, Hashable, Sendable {
    let providerID: String
    let modelID: String
}
```

### `ConfigInfo`, `HealthInfo`
```swift
struct HealthInfo: Codable, Sendable {
    let healthy: Bool
    let version: String
}

struct ConfigInfo: Codable, Sendable {
    let model: String?
    let theme: String?
    let agents: AnyCodable?
    // Just fetch what's needed; the full config schema is huge.
}
```

### `PromptBody`
```swift
struct PromptBody: Encodable, Sendable {
    let parts: [PromptPart]
    var model: ModelRef?
    var agent: String?
    var system: String?
}

enum PromptPart: Encodable, Sendable {
    case text(String)
    case file(mediaType: String, url: String, filename: String?)
    
    func encode(to encoder: Encoder) throws { /* discriminator + payload */ }
}
```

---

## 9. Server API Surface

These are the endpoints v1 hits. Exact HTTP details below. The `directory` query parameter is appended to **every** session/message/prompt call. Default `directory` comes from the active project. Auth header is HTTP Basic if password is configured.

### Health & Discovery
| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/global/health` | Verify server reachable + version |
| `GET` | `/global/event?directory={d}` | SSE event stream |

### Projects
| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/project` | List all projects |
| `GET` | `/project/current?directory={d}` | Get current project for a directory |

### Config & Providers
| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/config?directory={d}` | Get merged config |
| `GET` | `/config/providers?directory={d}` | List providers and default models |

### Sessions
| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/session?directory={d}` | List sessions |
| `POST` | `/session?directory={d}` | Create session, body: `{ title? }` |
| `GET` | `/session/{id}?directory={d}` | Get session |
| `PATCH` | `/session/{id}?directory={d}` | Update title, body: `{ title }` |
| `DELETE` | `/session/{id}?directory={d}` | Delete |
| `GET` | `/session/{id}/message?directory={d}` | List messages (returns `[{ info: Message, parts: [Part] }]`) |

### Prompting
| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/session/{id}/message?directory={d}` | Send a user message + prompt, wait for full reply. Body: `PromptBody`. Returns `{ info: AssistantMessage, parts: [Part] }`. **For v1 we don't use this — we use the streaming alternative below.** |
| `POST` | `/session/{id}/prompt?directory={d}` | Start an async prompt. Returns immediately (or after submission). UI updates from SSE events. Body: `PromptBody`. **This is what v1 calls.** |
| `POST` | `/session/{id}/interrupt?directory={d}` | Cancel running operation |

> **NOTE on streaming:** opencode's prompt POST does kick off an AI loop and the response body returns when complete; meanwhile the SSE stream emits delta events. For an iOS chat app with streaming, the right model is: POST `/session/{id}/prompt` (don't await the body for token streaming), let SSE deltas drive the UI, and use `/interrupt` for abort. If `/session/{id}/prompt` does not exist or behaves unexpectedly on the user's server build, fall back to `/session/{id}/message` and rely on SSE for streaming feel — the response body comes back when done either way.
>
> **Action item for the agentic coder when integrating:** verify the prompt endpoint's exact name and response shape against the user's running server. The endpoint catalog has shifted versions; the JS SDK calls it `client.session.prompt({...})`. The Swift client should expose `sendPrompt(...)` and may need a tiny tweak when wired up.

### Permissions
| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/permission/{permissionID}?directory={d}` | Respond. Body: `{ response: "allow" | "deny" | "always", remember?: bool }` |

### Files & Diffs (v1 read-only)
| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/file/content?path={path}&directory={d}` | Read a file (used by diff view if needed) |

### Logs
| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/log?directory={d}` | Optional: write client log entry to server |

---

## 10. Realtime: SSE Event Protocol

**Endpoint:** `GET /global/event?directory={activeDirectory}`

**Headers:**
- `Authorization: Basic <base64>` (if configured)
- `Accept: text/event-stream`

**Stream format:** standard SSE.
```
event: server.connected
data: {}

event: message.part.delta
data: {"type":"message.part.delta","properties":{"sessionID":"sess_x","messageID":"msg_y","partID":"prt_z","field":"text","delta":"Hello "}}
```

Each `data:` line is a single JSON object with a `type` string and a `properties` object. Decode `ServerEvent`, dispatch to `ChatStore`, `SessionStore`, `PermissionStore` as appropriate.

### Delta application

When a `message.part.delta` event arrives:
1. Locate the part in the active session by `partID`.
2. If `field == "text"` and the part is `.text` or `.reasoning`, **append** `delta` to the existing `text` field.
3. For unknown fields, silently ignore (log to debug).
4. If the part doesn't exist yet (event arrived before `message.part.updated`), buffer the delta in a `pendingDeltas: [String: String]` dictionary keyed by partID. When the next `message.part.updated` for that partID lands, drain the buffer.

### Reconnection

`EventStream` should auto-reconnect on disconnect with exponential backoff (start at 500ms, cap at 30s). On reconnect, the consumer (ChatStore) should refetch `/session/{id}/message` to resync, in case events were missed.

### Filtering

Only events for the active project's `directory` arrive (server filters by query param). Within that, events for sessions that aren't currently open in the chat view should still be observed by `SessionStore` (to update titles, last-modified) but not applied to `ChatStore`.

---

## 11. State & Sync Architecture

```
AppModel  (top-level @MainActor @Observable, owned by App, passed through @Environment)
├── activeProfile: ServerProfile?
├── client: OpencodeClient?           // built from activeProfile
├── projectStore: ProjectStore
├── sessionStore: SessionStore
├── chatStore: ChatStore?             // optional — only when a session is open
├── providerStore: ProviderStore
├── permissionStore: PermissionStore
└── eventStreamTask: Task<Void, Never>?
```

**Lifecycle:**
1. App launches → `RootView` reads Keychain. If no profile, show `SetupView`. Otherwise build `AppModel` with active profile, create `OpencodeClient`, hand to stores.
2. `AppModel.start()` calls `client.health()`, populates `ProjectStore`, picks an active project (last-used from `AppPreferences`, fall back to current).
3. `AppModel.subscribeToEvents()` opens the SSE stream and dispatches events into stores. Restarts on profile or active-project change.
4. User opens a session → create a `ChatStore` for that session (ChatStore loads message history once via REST, then receives events via the existing stream).
5. User sends prompt → `ChatStore.send(text:)` posts to `/session/{id}/prompt`, optimistically adds a user message to the timeline, awaits SSE deltas to populate the assistant turn.

**ChatStore responsibilities:**
- `messages: [Message]` and `parts: [String: [Part]]` (keyed by messageID)
- `turns: [Turn]` — derived
- `working: Bool` — true when the active session has an in-flight assistant message
- `apply(_ event: ServerEvent)` — mutate state for events relevant to this session
- `pendingDeltas: [String: String]` — buffer for early-arriving deltas
- `send(text:attachments:)` — POST prompt
- `interrupt()` — POST interrupt

**SessionStore responsibilities:**
- `sessions: [Session]` for active project
- React to `session.updated`, `session.deleted` events
- `create(title:)`, `delete(_:)` calls

**ProjectStore responsibilities:**
- `projects: [Project]`, `activeProject: Project?`
- `setActive(_:)` — persists choice to `AppPreferences`, triggers downstream reload
- `refresh()` — re-fetches list

**PermissionStore responsibilities:**
- `pending: [Permission]`
- `respond(to:response:remember:)`

---

## 12. Feature Inventory & Screens

### Setup (first launch / no profile)
- Form with: Server Name, Server URL, Username (default "opencode"), Password.
- "Test Connection" button → `client.health()` → green check or error.
- "Save & Connect" stores in Keychain and proceeds.

### Server Profile picker (sheet, accessible from Settings)
- List of saved profiles. Tap to switch active. Edit / delete via swipe actions or context menu. "Add Profile" button.

### Root navigation map
```
RootView
├── (if no profile) SetupView
└── (if profile) NavigationStack
    ├── SessionListView                           ← root
    │   toolbar:
    │     - leading: Settings gear
    │     - title: ProjectMenu (tappable, shows checkmark menu of projects)
    │     - trailing: New Session ("plus")
    │   navigationDestination(for: Session.self) → ChatView
    └── ChatView
        toolbar:
          - leading: back
          - title: ProjectMenu (same widget)
          - trailing: Model picker button → sheet, Abort button (when working)
```

`navigationDestination(for: Session.self)` is registered exactly once in `SessionListView`.

### SessionListView
- `List` of sessions sorted by `time.updated` desc.
- Each row: title (bold), last-updated relative time, small chevron, swipe-to-delete.
- Empty state: `ContentUnavailableView` with "No sessions yet" + "New Session" button.
- `.refreshable` triggers `sessionStore.refresh()`.
- `.searchable` filters by title using `localizedStandardContains`.

### ChatView
The main screen. Vertical layout:
1. **Permission dock** (top, conditional) — shows count of pending permission requests + tap to open `PermissionSheet`.
2. **Todo dock** (top, conditional) — collapsed bar with current todo count; tap to expand.
3. **Message timeline** (center, scrollable) — `LazyVStack` of `TurnView`. Auto-scrolls on new content unless user has manually scrolled up.
4. **Composer** (bottom) — `TextField(axis: .vertical, lineLimit: 1...8)`, attachment button (paperclip), send button (paper plane / square stop while working). The whole row sits in a Material background.

While `chatStore.working`:
- Show `ThinkingIndicatorView` shimmer if no assistant text yet
- Send button becomes Stop button
- Composer remains enabled (next prompt queues — actually opencode returns BusyError, so disable composer and show "Working…" placeholder)

### TurnView
For one user message + N assistant messages:
1. `UserMessageView` (right-aligned bubble, accent color background, rounded)
2. For each assistant part (filtered + grouped):
   - text → `TextPartView`
   - reasoning → `ReasoningPartView` (if `showReasoningSummaries` enabled — for v1 default true)
   - tool → dispatch via `ToolPartView`
   - compaction → `CompactionPartView` (a divider line)
3. After done, if `summary.diffs` present → "Modified N files" collapsible → expand to `DiffView`s
4. Error card if `error` present

Consecutive `read`/`glob`/`grep`/`list` tool parts get wrapped in `ContextToolGroupView` ("Gathered context · 3 reads, 1 search").

### Tool views
Each tool has a `BasicToolView` shell — collapsible with header (icon, title, subtitle) and body (output). Status drives visual: pending (orange dot), running (shimmer), error (red icon), completed (checkmark).

| Tool | Header title | Header subtitle | Body |
| --- | --- | --- | --- |
| `bash` | "Run command" | command preview | `Text` mono with output |
| `edit`/`write` | "Edit" / "Write" | filename | inline diff if `output` includes one, otherwise just status |
| `read` | "Read" | filename | none (counts in group label) |
| `glob` | "Glob" | pattern | match count |
| `grep` | "Grep" | pattern | match count + first few results |
| `list` | "List" | directory | entry count |
| `task` | "Sub-agent" | task description | nested message rendering (v1: just show "Sub-agent ran") |
| `question` | n/a, hidden when pending — see PermissionDock | | |
| `todowrite`/`todoread` | always hidden | | drives TodoDockView instead |

### PermissionSheet
Per pending permission: a `Form`-style card with:
- Tool name + icon
- Pattern / preview (e.g. command for bash, path for write)
- Three buttons: **Deny**, **Allow Once**, **Always Allow** (the last one only for repeat-pattern tools).

### TodoDockView
Collapsed: "3 todos · 1 in progress" pill.
Expanded: a small list of todos with status icons (circle / circle.dotted / checkmark.circle).

### Model picker sheet
List of providers, expand to models. Tap to select. Persisted in `AppPreferences` per profile. Shows current selection at top.

### Settings
- Active profile (tap → manage)
- Default model
- Show reasoning summaries (toggle)
- App info (version, opencode server version from health)

---

## 13. Per-File Specifications

For each file: a brief on what it contains and any non-obvious detail. Order is roughly bottom-up.

### App layer

**`App/OpencodeApp.swift`**
- `@main struct OpencodeApp: App`
- Single `WindowGroup { RootView() }`
- No scene phase work; SetUp via RootView.

**`App/RootView.swift`**
- `@State private var appModel: AppModel?`
- On `task`, attempts to load active `ServerProfile` from `ServerProfileStore`. If found, builds `AppModel`, calls `await appModel.start()`. If not, presents `SetupView`.
- Once `appModel` exists: passes via `.environment(appModel)` to a `MainTabsView` or directly to `NavigationStack` containing `SessionListView`. (V1 has only sessions; no tabs.)

**`App/AppModel.swift`**
- `@MainActor @Observable final class AppModel`
- Owns: `client`, all stores, `eventStreamTask`
- `start() async` — health check, populate stores, kick SSE
- `switchProfile(_ newProfile: ServerProfile) async` — tear down, rebuild
- `setActiveProject(_:)` — propagates to stores, restarts SSE with new directory
- Holds an `@MainActor`-isolated state. SSE consumer pumps events into stores via main actor hops.

### API layer

**`API/HTTPMethod.swift`** — small enum, `case get, post, patch, delete; var rawValue: String`.

**`API/BasicAuth.swift`** — utility: `func basicAuthHeader(username: String, password: String) -> String`.

**`API/OpencodeError.swift`** — `enum OpencodeError: Error, LocalizedError` with cases `httpStatus(Int, String?)`, `decoding(Error)`, `transport(Error)`, `unauthenticated`, `notFound`, `serverBusy`, `cancelled`. Provide `errorDescription`.

**`API/OpencodeClient.swift`** — `actor OpencodeClient`. Init takes `(baseURL: URL, profile: ServerProfile)`. Internal `URLSession` (custom timeouts: 60s request, 600s resource). `JSONDecoder` configured with appropriate `keyDecodingStrategy` (default — confirm against real responses; flip to `.convertFromSnakeCase` if needed). All endpoint methods listed in §9 as `async throws` methods. URL building helper that always appends `directory` query param when `directory` is non-nil.

Method shape:
```swift
func listSessions(directory: String) async throws -> [Session]
func createSession(directory: String, title: String?) async throws -> Session
func deleteSession(id: String, directory: String) async throws
func messages(sessionID: String, directory: String) async throws -> [MessageEnvelope]
func sendPrompt(sessionID: String, directory: String, body: PromptBody) async throws
func interrupt(sessionID: String, directory: String) async throws
func providers(directory: String) async throws -> ProviderListResponse
func health() async throws -> HealthInfo
func projects() async throws -> [Project]
func currentProject(directory: String?) async throws -> Project?
func respondToPermission(id: String, directory: String, response: String, remember: Bool) async throws
```

`MessageEnvelope` is a small Codable: `{ info: Message, parts: [Part] }`. Define in `Models/MessageEnvelope.swift` (add this file).

**Streaming method:**
```swift
nonisolated func eventStream(directory: String) -> AsyncThrowingStream<ServerEvent, Error>
```
Implementation in `Realtime/EventStream.swift` (kept separate so the actor doesn't trap the long-lived task).

### Realtime

**`Realtime/EventStream.swift`** — pure function building an `AsyncThrowingStream<ServerEvent, Error>` from a base URL + auth + directory. SSE parsing: read `URLSession.bytes(for:).lines`, accumulate `event:` and `data:` lines, on blank line decode the data as `ServerEvent` and yield. On disconnect, the stream finishes; the consumer (AppModel) decides reconnect strategy.

Add a separate `Realtime/SSELineParser.swift`? No — keep it in EventStream.swift as a private helper, since this is one of the few legitimate cases of a private helper not deserving its own file. Mark it with `// Helper: SSE line accumulation. Tightly coupled.`

**`Realtime/DeltaApplier.swift`** — pure function: `func apply(delta: MessagePartDelta, to part: inout Part)`. Switch on part type and field name. Append for "text" on text/reasoning. Log + ignore otherwise.

### Models
One file per type as listed in §5. Keep them small and `Sendable`. Use `Hashable` everywhere (helpful for `ForEach` IDing and SwiftUI identity).

### Storage

**`Storage/ServerProfile.swift`** — struct with `id: UUID`, `name: String`, `url: URL`, `username: String`, `password: String`. Codable. Equatable.

**`Storage/ServerProfileStore.swift`** — `final class ServerProfileStore` (not `@Observable`; thread-safe via locks or just main-actor). Methods: `loadAll()`, `save(_:)`, `delete(_:)`, `setActive(_:)`, `loadActive()`. Backed by Keychain (kSecClassGenericPassword) with one keychain item per profile, identified by `service: "ai.opencode.client.ios", account: "profile.\(uuid)"`. Active profile ID stored in another keychain item or in `AppPreferences` (use `AppPreferences` since the ID itself isn't sensitive).

**`Storage/AppPreferences.swift`** — `@Observable @MainActor class AppPreferences`. Backs to `UserDefaults`. Stores: `activeProfileID: UUID?`, `lastActiveProjectID: [UUID: String]` (keyed by profile), `defaultModelByProfile: [UUID: ModelRef]`, `showReasoning: Bool`. Use a manually-written observation pattern (mutating a property writes to UserDefaults and triggers Observable change). **Do not use `@AppStorage`** — Observable + UserDefaults is the right combo here.

### State

**`State/ProjectStore.swift`** — `@MainActor @Observable final class ProjectStore`. Holds `projects: [Project]`, `active: Project?`. Methods: `refresh() async`, `setActive(_:)`. Notifies observers; consumer code reacts via SwiftUI bindings.

**`State/SessionStore.swift`** — same pattern. `sessions: [Session]`, `loading: Bool`. Methods: `refresh(directory:) async`, `create(title:directory:) async`, `delete(_:directory:) async`, `apply(_ event: ServerEvent)`.

**`State/ChatStore.swift`** — same pattern. Holds messages/parts dicts as described in §11. Properties: `turns: [Turn]` (derived via `@ObservationIgnored` cache + recomputation hook OR a computed property — prefer computed; profile if it becomes hot). Methods: `load(sessionID:directory:) async`, `send(text:directory:model:) async`, `interrupt(directory:) async`, `apply(_ event: ServerEvent)`. `working: Bool` tracked via session status events.

**`State/ProviderStore.swift`** — `@MainActor @Observable`. `providers: [ProviderInfo]`, `defaults: [String: String]`. `refresh(directory:) async`.

**`State/PermissionStore.swift`** — `@MainActor @Observable`. `pending: [Permission]`. `apply(_ event: ServerEvent)`. `respond(_:response:remember:directory:) async`.

### Features

**`Features/Setup/SetupView.swift`** — `Form` with `Section`s. Bound to `@State private var model = SetupModel()`. Test Connection and Save buttons. On save, hands result up via a callback closure `var onComplete: (ServerProfile) -> Void`. (Closure is fine here — it's a single short-lived callback, not stored long-term.)

**`Features/Setup/SetupModel.swift`** — `@MainActor @Observable final class SetupModel`. `name`, `urlText`, `username`, `password`, `testStatus: TestStatus` (enum: `idle`, `testing`, `ok(version)`, `failed(error)`). Methods: `test() async`, `build() -> ServerProfile?`. Validation: URL parsability, non-empty fields.

**`Features/Profiles/ServerProfilePickerSheet.swift`** — `List` of profiles, `.sheet(item:)` driven, returns selection via callback or environment.

**`Features/Profiles/AddProfileSheet.swift`** — wraps `SetupView` for the "add another profile" case.

**`Features/Projects/ProjectMenu.swift`** — a `Menu` with the title bound to `appModel.projectStore.active?.name ?? "Choose Project"`. Menu items: each project, with `.checkmark` indicator on the active. Tap → `setActiveProject(_:)`. This is used as a toolbar `principal` placement.

**`Features/Projects/ProjectMenuLabel.swift`** — the visual: project name + chevron.down, hit target ≥ 44pt, accessibility label "Switch project, currently \(name)".

**`Features/Sessions/SessionListView.swift`** — root list view. Pulls `appModel.sessionStore`. `.searchable` with `localizedStandardContains`. `.refreshable`. `navigationDestination(for: Session.self) { ChatView(session: $0) }`. Toolbar: settings gear leading, ProjectMenu principal, plus button trailing.

**`Features/Sessions/SessionRowView.swift`** — title, relative date (`Text(date, format: .relative(presentation: .named))`), chevron.

**`Features/Sessions/EmptySessionListView.swift`** — `ContentUnavailableView`.

**`Features/Chat/ChatView.swift`** — the big one. Composes:
```
VStack(spacing: 0) {
  PermissionDockView(...)        // conditional
  TodoDockView(...)               // conditional
  MessageTimelineView(...)        // .frame(maxHeight: .infinity)
  ChatComposer(...)
}
.toolbar { ... }
.task { await chatStore.load(...) }
```
Owns the `ChatStore` for this session via `@State private var store: ChatStore`. Observes app-level event store too (passed `permissionStore`).

**`Features/Chat/ChatToolbar.swift`** — toolbar content as a `ToolbarContent`. Includes ProjectMenu principal, model picker trailing, abort button trailing (visible during `working`).

**`Features/Chat/ChatComposer.swift`** — text field + buttons. `@FocusState`. `@State` for input text. Send action: `await store.send(text:)`. Stop action: `await store.interrupt()`.

**`Features/Chat/AttachmentPickerSheet.swift`** — `PhotosPicker` for images. Selected images converted to `PromptPart.file(...)` entries with data: URI base64. (Server expects URLs or base64-data URIs; v1 keeps it simple with base64.)

**`Features/Chat/TodoDockView.swift`** — collapsed pill. Tap → expand with `withAnimation`. Items: `Label(todo.content, systemImage: iconForStatus(todo.status))`.

**`Features/Chat/PermissionDockView.swift`** — banner showing pending count. Tap → present `PermissionSheet`.

**`Features/Chat/PermissionSheet.swift`** — sheet listing pending permissions with Allow/Deny/Always actions. Calls `permissionStore.respond(...)`.

**`Features/Chat/Messages/MessageTimelineView.swift`** — `ScrollView` + `LazyVStack` over `chatStore.turns`. `.scrollPosition` for auto-scroll. Detects manual scroll to disable auto-scroll until user scrolls back to bottom.

**`Features/Chat/Messages/TurnView.swift`** — composes `UserMessageView` + assistant content (text/reasoning/tool/diff/error).

**`Features/Chat/Messages/UserMessageView.swift`** — right-aligned bubble. Pulls text from any non-synthetic `TextPart`. Inline file attachment thumbnails. Copy button (overlay, fades in on hover/long-press). Metadata row: agent name (if AgentPart), model, time.

**`Features/Chat/Messages/AssistantMessageView.swift`** — renders the assistant's parts in order, applying context-grouping logic (consecutive read/glob/grep/list go through `ContextToolGroupView`).

**`Features/Chat/Messages/ThinkingIndicatorView.swift`** — `ShimmerView` + "Thinking…" text. Reduce Motion: replace shimmer with subtle opacity pulse.

**`Features/Parts/TextPartView.swift`** — `MarkdownText(part.text)`. Copy button overlay.

**`Features/Parts/ReasoningPartView.swift`** — same but `.foregroundStyle(.secondary)` and a subtle "Reasoning" label.

**`Features/Parts/CompactionPartView.swift`** — a `Divider` with overlaid label "Context compacted".

**`Features/Parts/ToolPartView.swift`** — dispatcher: switches on `part.tool`, returns the right view from `Features/Parts/Tools/`. Falls back to `GenericToolView` for unknown tools. Hides `todowrite`/`todoread` (returns `EmptyView`). Hides `question` while pending (the permission dock handles it).

**`Features/Parts/ToolInfoMap.swift`** — `enum ToolInfoMap { static func info(for: String, input: AnyCodable?) -> (icon: String, title: String, subtitle: String?) }`. Hard-coded icon/title pairs for known tools.

**`Features/Parts/BasicToolView.swift`** — the collapsible shell. Props: `info`, `status`, `defaultOpen`, `content: Content` (`@ViewBuilder let content: Content`, stored as built value per perf rule). Expand state via `@State private var isExpanded`.

**`Features/Parts/ContextToolGroupView.swift`** — wraps multiple consecutive context tools into one collapsible "Gathered context · …".

**`Features/Parts/GenericToolView.swift`** — generic display of input + output as JSON in a code block.

**`Features/Parts/Tools/BashToolView.swift`** — shows command in mono, then output. Long output in `ScrollView { Text(...) }` with max height.

**`Features/Parts/Tools/EditToolView.swift`**, **`WriteToolView.swift`** — show filename, then a `DiffView` if the tool output contains diff info, otherwise just status.

**`Features/Parts/Tools/ReadToolView.swift`**, **`GlobToolView.swift`**, **`GrepToolView.swift`**, **`ListToolView.swift`** — minimal individual views (will mostly be invoked via context group; this is the standalone fallback).

**`Features/Parts/Tools/TaskToolView.swift`** — for v1: just show "Sub-agent: \(input.description)". Don't recurse into sub-session rendering.

**`Features/Parts/Tools/QuestionToolView.swift`** — placeholder; question parts in pending state are hidden, and PermissionSheet handles user interaction.

**`Features/Diff/DiffView.swift`** — simple unified diff renderer. Takes `before: String?, after: String?`. Computes line-level diff (use a simple LCS implementation; no third-party). Renders monospace lines with `+`/`-` prefixes and red/green backgrounds.

**`Features/Diff/DiffStatsBar.swift`** — small visual: `+5 -3` with a stacked bar.

**`Features/Models/ModelPickerSheet.swift`** — list of providers; `DisclosureGroup` per provider; rows are `ModelRowView`. Selection fires a callback. Persists to `AppPreferences`.

**`Features/Models/ModelRowView.swift`** — model name, optional context limit and pricing as `.secondary` subtitle.

**`Features/Settings/SettingsView.swift`** — `Form` with sections: Profile, Defaults, About. Profile section shows current profile name, "Switch Profile" button → `ServerProfilePickerSheet`. Defaults: model picker, show-reasoning toggle. About: app version + server version + opencode version.

**`Features/Settings/ProfileEditView.swift`** — edit a single profile.

### Shared

**`Shared/DesignTokens.swift`** — already specified.

**`Shared/MarkdownText.swift`** — `struct MarkdownText: View`. Takes a string. Renders via `Text(AttributedString(markdown:))` with `.fullDocument` interpretation. Handles errors by falling back to plain text. Use `.textSelection(.enabled)`.

**`Shared/CopyButton.swift`** — small button that copies a given string to `UIPasteboard` and fires a sensoryFeedback.

**`Shared/ShimmerView.swift`** — animated gradient shimmer. Respects Reduce Motion.

**`Shared/CollapsibleSection.swift`** — generic collapsible. Header View + Content View. Used anywhere we need a custom collapsible (BasicToolView wraps this).

**`Shared/ContentUnavailableViews.swift`** — typed factory functions: `noProfile()`, `noProjects()`, `noSessions()`, `connectionError(_ error:)`. Returns `ContentUnavailableView`s.

**`Shared/DateFormatting.swift`** — extension on `Date` providing common formatted strings via `FormatStyle`. **Do not** create `DateFormatter` instances.

**`Shared/HapticFeedback.swift`** — small enum or struct providing sensoryFeedback trigger helpers (success, warning, selection). All using SwiftUI's `.sensoryFeedback()` modifier — provide a tiny VM-style trigger struct that views attach to.

**`Shared/EnvironmentKeys.swift`** — uses `@Entry` to define any custom environment values (e.g. an `OpencodeClient?` if not propagated through AppModel — though most things propagate through `AppModel`).

### Tests

**`Tests/PartCodingTests.swift`** — Codable round-trip for each Part variant. Sample JSON fixtures inline.

**`Tests/DeltaApplierTests.swift`** — apply text deltas, ignore unknown fields, test buffering for early deltas.

**`Tests/ServerEventDecodingTests.swift`** — parse representative SSE events, ensure dispatch is correct.

**`Tests/EndpointBuilderTests.swift`** — verify URLs constructed by `OpencodeClient` for each endpoint, especially the `directory` query param escaping.

**`Tests/ToolInfoMapTests.swift`** — verify icon/title for each known tool.

Use Swift Testing (`@Test func`), not XCTest, for iOS 26 modernity.

---

## 14. Implementation Order

(Suggestion for the agentic coder downstream.)

1. Models + AnyCodable (everything depends on these)
2. API/OpencodeClient skeleton + endpoints (no streaming yet)
3. Realtime/EventStream + DeltaApplier
4. Storage layer (ServerProfile + ServerProfileStore + AppPreferences)
5. State stores
6. App + RootView + Setup
7. Sessions list
8. Chat skeleton (no parts yet)
9. Parts + Tools + Diff
10. Permission flow
11. Model picker
12. Settings
13. Tests
14. Polish: empty states, accessibility audit, haptics

---

## 15. Output Format Required from You

You will produce **all the Swift files listed above**. Use this exact format so the downstream agentic coder can split them programmatically:

````
// FILE: Opencode/App/OpencodeApp.swift

import SwiftUI

@main
struct OpencodeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
````

— each file in its own fenced ` ```swift ` code block, with the very first line being `// FILE: <path>`. The path is the full path under the project root (e.g. `Opencode/Features/Chat/ChatView.swift`).

Order the files top-down by dependency: leaf models first, then Codable wrappers, then API client, then storage, then state, then features, then app, then tests.

If you run out of output room before all files are generated:
- End your response with `// CONTINUE: <next-file-path>`
- The user will reply with "continue" and you pick up from that file.

**Do not include preamble, explanations, or summaries between files.** The downstream coder doesn't need them. Code only, with `// MARK:` and inline `// NOTE:` comments where useful.

**At the very end of the very last response**, append a single block:

````
// END_OF_FILES
````

so the coder knows it's complete.

---

## 16. Things Explicitly Out of Scope (v1)

Do not implement, even tempting:
- Terminal panel / PTY WebSocket
- File tree browsing or in-app file editing
- Workspace management UI
- Session forking
- Session sharing UI
- LSP diagnostics surfaces
- MCP server config UI
- Theme switcher / appearance settings
- Localizable.xcstrings (English only for v1)
- Apple Watch / iPad-specific layouts (universal works fine on iPad with no special handling)
- Push notifications when prompts complete
- Search across sessions/messages
- mDNS / NWBrowser auto-discovery (defer to v2 — but the architecture should not preclude it)
- Background execution / app-lifecycle SSE re-subscription beyond simple foreground/background restart
- iCloud sync of profiles
- Onboarding tour
- Crash reporting

---

## 17. Acceptance Checklist

The downstream agentic coder will use this. Before declaring v1 done:
- [ ] Project builds with no warnings under Swift 6 strict concurrency
- [ ] `swift test` passes (or `xcodebuild test` for the app target)
- [ ] Connect to `opencode serve` on localhost: see project list, sessions list, messages load
- [ ] Send a prompt → see streaming text in real time via SSE
- [ ] Tool calls render with collapsibles (try a prompt that triggers `bash` and `read`)
- [ ] Permission prompt appears for write/edit and can be allowed/denied
- [ ] Project menu in toolbar switches active project, sessions reload
- [ ] Profile picker in settings switches active profile, full reload happens
- [ ] VoiceOver pass: every button has a label, every meaningful image has a description
- [ ] Dynamic Type pass: app remains usable at xxxLarge
- [ ] Reduce Motion: no jarring animations
- [ ] Keychain persists across app restarts
- [ ] Aborts work: send a long prompt, hit stop, server-side prompt is interrupted

---

## A note on ambiguity

Some opencode endpoint semantics, especially around the streaming prompt endpoint, may not match this document exactly. The user's running server is the source of truth. If during integration the agentic coder discovers (e.g.) that the prompt endpoint is `/session/{id}/message` and not `/session/{id}/prompt`, they should:
1. Adjust `OpencodeClient.sendPrompt(...)`
2. Confirm SSE events still drive the UI (they should — events are independent of HTTP method)
3. Document the change in a `// NOTE:` comment

Spec drift is expected. The architecture is robust to it.

---

End of plan. Generate the files.
