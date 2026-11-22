# 2. Technology stack

Choices for language, frameworks and tooling, with the alternatives considered. Requirement IDs refer to [Functionality](01-functionality.md).

## Summary

| Area | Choice |
|---|---|
| Language | Swift 6, strict concurrency |
| UI | AppKit |
| Window control | Accessibility API (`AXUIElement`, `AXObserver`) |
| Keyboard input | One `CGEventTap` |
| Build | Swift Package Manager, plus a script that assembles and signs the `.app` |
| Tests | Swift Testing |
| Launch at login | `SMAppService.mainApp` |
| Minimum macOS | 14 (Sonoma) |
| Distribution | Unsandboxed app outside the App Store. See [Distribution](06-distribution.md). |

## Language: Swift 6

Swift is the native language for AppKit and the Accessibility API, and it's what AeroSpace, Rectangle and AltTab use, so their code serves as reference. Strict concurrency catches races between the event tap, AX callbacks and UI at compile time.

Alternatives:
- Objective-C: same APIs, weaker type system, no gain.
- Rust (`objc2`, `accessibility-sys`): workable, but AppKit through bindings is verbose and reference material is scarce.
- Hammerspoon (Lua): fast to prototype, but it's a scripting host, not a product, and the switcher UI would be constrained.

## UI: AppKit

The UI is two small surfaces: a menu bar item and the switcher panel. The panel must be non-activating (`NSPanel` with `.nonactivatingPanel`) and float above all windows, so showing it never takes focus from the app being switched away from. This is AppKit territory.

SwiftUI was considered for the panel contents. It would make layout shorter, but a grid of icon and title tiles is little code in AppKit, and non-activating panels are fragile in SwiftUI.

## Window control: Accessibility API

All window operations go through the public Accessibility API:

| Need | API |
|---|---|
| Enumerate windows | `kAXWindowsAttribute` per running app |
| Focused window | `kAXFocusedWindowAttribute` on the frontmost app |
| Move and resize | `kAXPositionAttribute`, `kAXSizeAttribute` |
| Focus | `kAXMainAttribute` and `kAXRaiseAction`, then cooperative activation |
| Filter real windows | `kAXSubroleAttribute == kAXStandardWindowSubrole` |
| Minimized, fullscreen | `kAXMinimizedAttribute`, `"AXFullScreen"` |
| Focus changes | `AXObserver` for focused window changed, `NSWorkspace` app activation |
| Titles and icons | `kAXTitleAttribute`, `NSRunningApplication.icon` |

Window identity: an `AXUIElement` is stable for the life of a window and supports `CFEqual` and `CFHash`, so it can key a dictionary. AeroSpace and AltTab use the private `_AXUIElementGetWindow` to get a `CGWindowID`. We don't need one, and the public-APIs-only principle rules it out.

AX calls are synchronous IPC to the target app. A hung app blocks the caller, by default for about 6 s. We set `AXUIElementSetMessagingTimeout` to 0.5 s.

No Screen Recording permission is needed. Titles come from AX.

## Keyboard input: one `CGEventTap`

The switcher can't be built with registered hotkeys (Carbon `RegisterEventHotKey`): it needs the release of ⌥ (SW-5). That requires watching `flagsChanged` and `keyDown` events, which takes an event tap. An active tap is covered by the Accessibility permission we already need.

Since the tap is required anyway, it also handles the tiling shortcuts. One input path means one place where shortcuts are matched and swallowed.

Risks:
- macOS disables a tap whose callback is slow (`kCGEventTapDisabledByTimeout`). The callback only matches events and hands work to the main thread, and the tap re-enables itself when it is disabled.
- Secure input (password fields, some terminals with Secure Keyboard Entry) blocks event taps. Shortcuts don't work while it is on. This is a known limitation that every tap-based tool shares.

## Build: SwiftPM and a bundle script

The repository is a Swift package:

- `SimpleTileCore`: library with the logic that doesn't need macOS (geometry, input matching, switcher state, focus history).
- `SimpleTile`: executable with the AX code, event tap, AppKit UI, and app lifecycle.
- `SimpleTileCoreTests`: tests for the core.

`scripts/bundle.sh` runs `swift build -c release` for arm64 and x86_64, assembles `SimpleTile.app` with an `Info.plist` (`LSUIElement = YES` for no Dock icon, per APP-1) and an icon built from `Resources/AppIcon.png`, writes `$VERSION` and `$BUILD_NUMBER` into the `Info.plist`, and signs it. `scripts/package.sh` zips the app for a release. `scripts/install.sh` bundles, copies the app to `~/Applications`, and relaunches it.

The Command Line Tools build both architectures in one `swift build`; Xcode is not needed.

There's no Xcode project. `Package.swift` is the only build definition, it opens in Xcode and other IDEs, and it works from the command line and CI.

## Code signing

macOS ties the Accessibility permission to the app's signature. With ad-hoc signing, every rebuild looks like a new app and the permission has to be granted again.

- Development: a self-signed code signing certificate created once in Keychain Access (Certificate Assistant, type "Code Signing"), passed to the scripts as `$SIMPLETILE_SIGN_IDENTITY`. Free, and it gives a stable identity across rebuilds.
- Distribution: see [Distribution](06-distribution.md).

The app can't be sandboxed: the App Sandbox doesn't allow controlling other apps through AX. So no App Store.

## Testing

Swift Testing (`@Test`, `#expect`) for all automated tests. Details in the [test strategy](04-test-strategy.md).

## Tooling

- Formatting: `swift-format`, which ships with the Swift 6 toolchain. Config in `.swift-format`.
- CI: GitHub Actions on a macOS runner, running build and tests. Assumes the project goes to GitHub. It isn't a git repository yet.
- Debugging AX: Accessibility Inspector, which ships with Xcode, shows the AX tree of any app.

## Environment: Command Line Tools only

Xcode is not available on the development machine, so the project builds and tests with the Command Line Tools alone (Swift 6.4.2, macOS 27.2 SDK).

- XCTest is not part of the Command Line Tools. Swift Testing is, but its macro plugin (`usr/lib/swift/host/plugins/testing`) is not on the compiler's default plugin path. `Package.swift` adds `-plugin-path` for the test target when Xcode is absent, and `swift test` works.
- Without Xcode there is no Accessibility Inspector or Instruments. AX trees can be inspected with a small script instead.

## Decided against

- Private APIs (`CGS*`, `SkyLight`, `_AXUIElementGetWindow`): rejected by principle.
- ScreenCaptureKit for thumbnails: out of scope, and it would add the Screen Recording permission.
- Electron or web UI: heavy for two small surfaces, and native APIs would still be needed.
