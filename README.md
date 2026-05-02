# Anvil for OpenCode

Anvil for OpenCode is a native iOS client for [opencode](https://github.com/sst/opencode). It connects to a self-hosted `opencode serve` instance and lets you browse projects, resume sessions, send prompts, follow streamed assistant output, review tool activity, and answer permission prompts from an iPhone or iPad.

The app is built for developers who already run opencode on a Mac, Linux box, homelab server, or Tailscale-accessible machine.

## Status

This is an early iOS implementation. The core client, session, chat, streaming, permission, model-picker, and diff-rendering pieces are in place, but the app is still being hardened against opencode API drift and real server behavior.

## Features

- Multi-profile server setup with credentials stored in Keychain.
- Project discovery and project switching.
- Session list with search, create, delete, and refresh.
- Chat timeline grouped into user/assistant turns.
- SSE streaming through `/global/event`.
- Incremental text and reasoning deltas.
- Tool-call rendering for common opencode tools: bash, read, write, edit, grep, glob, list, task, and question.
- Non-blocking permission review with allow once, allow always, and reject actions.
- Provider/model discovery with persisted default model preference.
- Lightweight file diff rendering.
- Swift Testing coverage for endpoint building, event decoding, part decoding, delta application, and tool metadata.

## Requirements

- Xcode 17 or newer.
- iOS 26 SDK.
- A running opencode server reachable from the device or simulator.

Start opencode on your development machine:

```sh
opencode serve --hostname 0.0.0.0 --port 4096
```

If you set `OPENCODE_SERVER_PASSWORD`, enter that password in the app setup screen. The default username is `opencode`.

## Running

1. Open `Anvil for OpenCode.xcodeproj` in Xcode.
2. Select the `Anvil for OpenCode` scheme.
3. Build and run on an iOS simulator or device.
4. Add a server profile using a URL such as `http://127.0.0.1:4096` for simulator use, or your Mac/server LAN or Tailscale address for a physical device.

## Validation

Current validation commands:

```sh
xcodebuild -project 'Anvil for OpenCode.xcodeproj' -scheme 'Anvil for OpenCode' -destination 'generic/platform=iOS' build
xcodebuild -project 'Anvil for OpenCode.xcodeproj' -scheme 'Anvil for OpenCode' -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Architecture

- `API/` contains the actor-isolated opencode HTTP client and auth/error helpers.
- `Realtime/` contains the SSE stream reader and delta applier.
- `Models/` contains Codable wire models for projects, sessions, messages, parts, tools, permissions, providers, and events.
- `State/` contains `@MainActor @Observable` stores for projects, sessions, chat, providers, and permissions.
- `Storage/` contains Keychain-backed server profile persistence and UserDefaults preferences.
- `Features/` contains SwiftUI screens and feature-specific views.
- `Shared/` contains reusable UI and formatting helpers.
- `Tests/` contains Swift Testing suites.

## Notes

The opencode server API is still moving. The client currently prefers the modern prompt, abort, and permission endpoints while keeping fallbacks for older server versions. Unknown tool states and future part types are decoded defensively so a new server field is less likely to break the whole chat load.

## Not Included Yet

- Terminal panel.
- File tree browsing or editing.
- Full opencode settings surface.
- Session forking or sharing.
- LSP diagnostics.
- Push notifications.
- iCloud profile sync.
