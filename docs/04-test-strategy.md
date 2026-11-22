# 4. Test strategy

- Every requirement ID in [Functionality](01-functionality.md) has a test or a manual check. `scripts/check-traceability.sh` fails otherwise. Test names start with the IDs they verify: `@Test("SW-3: opens with the second entry selected")`.
- Behaviour is tested in the pure core (`SimpleTileCoreTests`). Line coverage of `SimpleTileCore` must stay at or above 90%.
- What the core can't see (AX, real apps, the event tap, the panel) is checked by hand before each release.

## Core tests

- `GeometryTests`: halves and fill, odd widths, displays at negative coordinates, AppKit to AX conversion, `bestArea`.
- `InputMatcherTests`: every shortcut, swallowing of keyDowns and their keyUps, pass-through of other keys and modifiers, fn and numeric pad flags, missed ⌥ release.
- `SwitcherTests`: initial selection, single entry, wrapping, no entries, focus history ordering.

## Manual checklist

On the newest macOS, with two displays for the display items.

- M-TIL-1 to M-TIL-3: tile on each display, with the Dock on the bottom and on a side.
- M-TIL-4: tile Terminal and System Settings.
- M-TIL-5: shortcuts do nothing on a fullscreen window and with only the Finder desktop focused.
- M-TIL-6: a tiled window can be moved and resized freely afterwards.
- M-SW-1: switcher panel with 1, 2, 5 and 20 windows, long titles, apps without icons. A quick ⌥Tab shows no panel.
- M-SW-2: windows on a second display are listed. Minimized windows are not.
- M-APP-1 to M-APP-3: menu bar item, menu entries, Launch at Login toggles and survives a log out, first-launch permission flow without restart.
- M-APP-4: launch the app twice, only one menu bar item appears.
- M-SEC: with Secure Keyboard Entry on in Terminal, shortcuts stop working and nothing breaks.

## CI

`.github/workflows/ci.yml`, on every push and pull request to `main`: build, tests with coverage, `scripts/check-coverage.sh 90`, `scripts/check-traceability.sh`, `swift format lint --strict`, and an ad-hoc signed bundle.
