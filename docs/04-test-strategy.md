# 4. Test strategy

How every requirement in [Functionality](01-functionality.md) is verified, given the design in [Architecture](03-architecture.md).

## Principles

- Every requirement ID has at least one test or manual check, and the mapping is checked automatically (see [Traceability](#traceability)).
- Behaviour is tested in the pure core wherever possible. The shell tests only what the core can't see: real AX calls, real apps, real input.
- Tests are written before the code they cover.
- No test depends on the developer's own open windows. Integration and end-to-end tests drive a test app the project builds.

## Levels

| Level | Target | What it tests | Needs | Runs in | Exists |
|---|---|---|---|---|---|
| L1 Core | `SimpleTileCoreTests` | Geometry, InputMatcher, SwitcherState, FocusHistory | Nothing | CI and locally, every build | Yes |
| L3 AX integration | `SimpleTileIntegrationTests` | `WindowSystem` against `TestApp` windows | Accessibility permission for the test runner | Locally | No |
| L4 End-to-end | `SimpleTileE2ETests` | Bundled app plus `TestApp`, driven by synthetic key events | Bundled, signed app with Accessibility permission | Locally, before each release | No |
| M Manual | [Checklist](#manual-checklist) | Visuals, feel, secure input, multiple displays, real apps | A person | Before each release | Yes |

L3 and L4 tests are disabled unless `WM_INTEGRATION=1` is set (Swift Testing `.enabled(if:)`), so `swift test` on a fresh machine or in CI never fails for lack of permission.

The Accessibility permission for L3 is granted to the process that runs `swift test`: Terminal, iTerm, or the IDE.

## L1: core tests

- `GeometryTests`: halves and fill, odd widths, displays at negative coordinates, AppKit to AX conversion, `bestArea`.
- `InputMatcherTests`: every shortcut, swallowing of keyDowns and their keyUps, pass-through of other modifier combinations and keys, fn and numeric pad flags, missed ⌥ release.
- `SwitcherTests`: initial selection, single entry, wrapping, no entries, focus history ordering.

Coverage: `swift test --enable-code-coverage`. Target: 90% line coverage for `SimpleTileCore`. No target for the shell, which is covered by L3, L4 and manual checks.

## L3: AX integration tests

### TestApp

A small AppKit app in the package (`Sources/TestApp`), controlled through stdin by the test process, one command per line:

| Command | Effect |
|---|---|
| `open <title> <w> <h>` | Open a standard window |
| `panel <title>` | Open a non-standard panel (must be ignored) |
| `close <title>` | Close a window |
| `minimize <title>`, `fullscreen <title>` | Change window state |
| `minsize <title> <w> <h>` | Set a minimum size |
| `activate <title>` | Bring the window to front from inside the app |
| `hang <seconds>` | Block the main thread |
| `keys` | Print the key events this app received since the last call |

Each test starts its own `TestApp` instances (several, for several pids) and terminates them at the end.

### What L3 covers

- `standardWindows()`: titles, empty title fallback, standard vs non-standard, minimized windows excluded.
- Tiling lands where requested, including minimum size (TIL-4), and does nothing for a fullscreen window (TIL-5).
- `AXEnhancedUserInterface` is restored after a move.
- `focus` makes the window frontmost without raising the app's other windows.
- `FocusTracker` records focus changes within an app and across apps.
- A hung app delays a call by no more than the 0.5 s timeout.

## L4: end-to-end tests

The bundled app and `TestApp` run together. The test posts synthetic key events with `CGEvent.post(tap: .cghidEventTap)`, which pass through the app's event tap like real keys. Results are checked through AX from the test process and through `TestApp`'s `keys` command.

L4 is kept small: one test per input path, to prove the wiring. Behaviour details are already covered in L1.

- ⌥⌃← tiles the focused `TestApp` window.
- ⌥Tab, Tab, release ⌥ focuses the right window, and `TestApp` received no Tab key.
- A second launch of the app quits, and shortcuts are handled once.

## Traceability

Test names start with the requirement IDs they verify:

```swift
@Test("SW-3: opens with the second entry selected")
```

Manual checks in the checklist below carry IDs the same way. `scripts/check-traceability.sh` extracts every ID from `01-functionality.md` and fails if one appears in no test name and no manual check. It runs in CI.

## Matrix

L1 Core, L3 AX integration, L4 End-to-end, M Manual.

### Tiling

| ID | L1 | L3 | L4 | M | Notes |
|---|---|---|---|---|---|
| TIL-1, TIL-2, TIL-3 | ✓ | ✓ | ✓ | | L1: geometry on several display layouts, odd widths |
| TIL-4 | | ✓ | | ✓ | Real apps: Terminal (resize steps), System Settings (fixed size) |
| TIL-5 | | ✓ | | ✓ | |
| TIL-6 | | | | ✓ | |

### Window switcher

| ID | L1 | L3 | L4 | M | Notes |
|---|---|---|---|---|---|
| SW-1 | ✓ | | ✓ | ✓ | M: looks right, icons and long titles, no flash on a quick ⌥Tab |
| SW-2 | ✓ | ✓ | | ✓ | M: windows on a second display are listed |
| SW-3 to SW-7 | ✓ | | | | |
| SW-8 | ✓ | | ✓ | | L4: `TestApp` receives no Tab |

### App lifecycle

| ID | L1 | L3 | L4 | M | Notes |
|---|---|---|---|---|---|
| APP-1, APP-2 | | | | ✓ | |
| APP-3 | | | | ✓ | Reset with `tccutil reset Accessibility <bundle id>` |
| APP-4 | | | ✓ | ✓ | |

## Manual checklist

Run before each release, on the newest macOS and with at least two displays for the display items. Results are recorded in the release notes.

- M-TIL-1 to M-TIL-3: tile on each display, with the Dock on the bottom and on a side.
- M-TIL-4: tile Terminal and System Settings.
- M-TIL-5: shortcuts do nothing on a fullscreen window and with only the Finder desktop focused.
- M-TIL-6: a tiled window can be moved and resized freely afterwards.
- M-SW-1: switcher panel with 1, 2, 5 and 20 windows, long titles, apps without icons, light and dark mode. A quick ⌥Tab shows no panel.
- M-SW-2: windows on a second display are listed. Minimized windows are not.
- M-APP-1 to M-APP-3: menu bar item, menu entries, Launch at Login toggles and survives a log out, first-launch permission flow without restart.
- M-APP-4: launch the app twice, only one menu bar item appears.
- M-SEC: with Secure Keyboard Entry enabled in Terminal, shortcuts stop working and nothing breaks. They work again once it is off.

App compatibility list, each checked for tiling and focus: Safari, Chrome, Firefox, Finder, Terminal, VS Code, Slack, Zoom, Mail, System Settings.

## CI

GitHub Actions, macOS runner, on every push:

1. `swift build`
2. `swift test --enable-code-coverage`, failing below 90% for the core (L3 and L4 skip themselves)
3. `scripts/check-traceability.sh`
4. `swift format lint --strict --recursive Sources Tests`
