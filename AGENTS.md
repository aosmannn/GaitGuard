# AGENTS.md

## Overview

GaitGuardAI is a native Apple Watch + iPhone app (Swift / SwiftUI) that monitors wrist motion and provides rhythmic haptic cueing for gait initiation and turning difficulties. See `README.md` for full product details.

### Project structure

- `GaitGuardAI/GaitGuardAI Watch App/` — watchOS app (Core Motion, state machine, haptics)
- `GaitGuardAI/GaitGuardAI-iPhone/` — iPhone companion app (analytics, remote controls)
- `GaitGuardAI/Shared/` — WatchConnectivity communication layer
- `GaitGuardAI/SessionManager.swift` — WKExtendedRuntimeSession management
- `GaitGuardAI/GaitGuardAI.xcodeproj` — Xcode project (no SPM, CocoaPods, or Carthage)

Zero third-party dependencies; all imports are Apple system frameworks.

## Cursor Cloud specific instructions

### Platform constraint

This is a pure Apple-platform project. **Building and running the app requires macOS + Xcode.** The Cloud Agent Linux VM cannot build or run the iOS/watchOS targets. The instructions below describe what *can* be done on the Linux VM.

### Available tools on the Linux VM

| Tool | Path | Purpose |
|---|---|---|
| Swift 6.0.3 (Linux) | `/opt/swift/usr/bin/swift` | Syntax checking via `swiftc -parse <file>` |
| SwiftLint 0.57.1 | `/usr/local/bin/swiftlint` | Linting Swift source files |

### Lint

```bash
cd GaitGuardAI && swiftlint lint
```

SwiftLint runs with default rules (no `.swiftlint.yml` in the repo). Expect ~359 warnings/errors, mostly `trailing_whitespace` and `identifier_name` for short variable names (`x`, `y`, `z`) used in motion processing.

### Syntax check

```bash
cd GaitGuardAI && swiftc -parse <file.swift>
```

All 10 Swift source files pass syntax checking. Note: `swiftc -parse` only validates syntax; it cannot type-check Apple framework imports on Linux.

### Tests

No automated test targets exist in the Xcode project. Testing requires physical Apple Watch + iPhone hardware with WatchConnectivity.

### Build & run (requires macOS)

1. Open `GaitGuardAI/GaitGuardAI.xcodeproj` in Xcode 15+.
2. Select scheme **GaitGuard Watch App** or **GaitGuardAI-iPhone**.
3. Run on simulator (UI only) or physical devices (full functionality).

See `README.md` "Running on Apple Watch" section for complete instructions.
