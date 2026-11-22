# 2. Technology stack

| Area | Choice |
|---|---|
| Language | Swift 6, strict concurrency |
| UI | AppKit |
| Window control | Accessibility API (`AXUIElement`, `AXObserver`) |
| Keyboard input | One `CGEventTap` |
| Build | Swift Package Manager, plus scripts that assemble, sign and zip the `.app` |
| Tests | Swift Testing |
| Launch at login | `SMAppService.mainApp` |
| Minimum macOS | 14 (Sonoma) |
| Distribution | Homebrew cask in our own tap. See [Releasing](05-releasing.md). |

## Why

- AppKit, not SwiftUI: the switcher must be a non-activating `NSPanel`, so showing it never takes focus from the app being switched away from. SwiftUI is fragile there.
- Public APIs only. Window identity is the `AXUIElement` itself (it supports `CFEqual` and `CFHash`), not the private `_AXUIElementGetWindow`. No Screen Recording permission: titles come from AX.
- AX calls are synchronous IPC to the target app, and a hung app blocks the caller for about 6 s by default. The messaging timeout is set to 0.5 s.
- An event tap, not Carbon hotkeys: the switcher needs the release of ⌥ (SW-5). Since the tap exists anyway, it handles tiling too, so shortcuts are matched in one place. macOS disables a slow tap, so the callback only matches and hands work to the main thread, and the tap re-enables itself. Secure input blocks every event tap; that is a known limitation.
- Not sandboxed: the App Sandbox doesn't allow controlling other apps through AX. So no App Store.

## Build

- `SimpleTileCore`: logic that doesn't need macOS (geometry, input matching, switcher state, focus history).
- `SimpleTile`: the executable with AX, the event tap, the UI and the lifecycle.
- `SimpleTileCoreTests`: tests for the core.

| Script | Does |
|---|---|
| `scripts/bundle.sh` | Universal (arm64, x86_64) release build, `SimpleTile.app` with icon and `Info.plist`, `$VERSION` and `$BUILD_NUMBER` written in, signed with `$SIMPLETILE_SIGN_IDENTITY` or ad hoc |
| `scripts/install.sh` | Bundle, copy to `~/Applications`, relaunch |
| `scripts/package.sh` | Zip the app with `ditto`, print the `sha256` |
| `scripts/cask.sh` | Print the Homebrew cask for a version and `sha256` |
| `scripts/check-traceability.sh` | Fail if a requirement ID has no test and no manual check |
| `scripts/check-coverage.sh` | Fail if `SimpleTileCore` line coverage is below the given percentage |

macOS ties the Accessibility permission to the app's signature, so an ad-hoc signed build has to be granted again after every rebuild. Signing local builds with the release certificate avoids that.

## Command Line Tools only

The project builds and tests without Xcode. XCTest isn't part of the Command Line Tools, but Swift Testing is. Its macro plugin isn't on the compiler's default plugin path, so `Package.swift` adds `-plugin-path` for the test target when Xcode is absent.
