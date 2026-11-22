# 1. Functionality

What the app does, from the user's point of view. Requirement IDs (`TIL-1`, `SW-3`, ...) are referenced by the test strategy.

## Terms

| Term | Meaning |
|---|---|
| Window | A standard top-level window (AX subrole `AXStandardWindow`) of a regular app. Sheets, popovers, panels and dialogs are not windows. |
| Main display | The display that holds the menu bar. |
| Usable area | A display's frame minus the menu bar and the Dock. |

## 1. Tiling

Tiling acts on the focused window, inside the usable area of the display that holds most of that window. It works on every display.

| ID | Shortcut | Result |
|---|---|---|
| TIL-1 | ⌥⌃← | Left half of the usable area |
| TIL-2 | ⌥⌃→ | Right half of the usable area |
| TIL-3 | ⌥⌃↑ | Whole usable area. This is not native fullscreen and creates no new Space. |

- TIL-4: If an app enforces a minimum size or resizes in steps, the window keeps its nearest allowed size and is aligned to the target's top-left corner.
- TIL-5: Shortcuts do nothing when no window is focused, or when the focused window is in native fullscreen.
- TIL-6: Tiling is not remembered. A tiled window behaves like any other window afterwards.

## 2. Window switcher

- SW-1: Holding ⌥ and pressing Tab (or ⇧Tab) opens a panel centered on the main display. Each entry shows the app icon and the window title, or the app name when the title is empty. The panel appears after 100 ms, so a quick ⌥Tab switches without it flashing.
- SW-2: Entries are the non-minimized windows on the current Space, on every display, most recently focused first. Windows never seen focused since launch follow.
- SW-3: The panel opens with the second entry selected, so a quick ⌥Tab returns to the previous window. With a single entry, that entry is selected.
- SW-4: Tab and → move the selection forward, ⇧Tab and ← move it backward, and all wrap around.
- SW-5: Releasing ⌥ focuses the selected window and closes the panel. If the release is missed, the next key event commits the same way.
- SW-6: Esc closes the panel without changing focus.
- SW-7: With a single window, ⌥Tab opens the panel showing only that window. With no windows, ⌥Tab does nothing.
- SW-8: While the panel is open, Tab, ⇧Tab, ←, → and Esc do not reach the focused app. Other keys do.

## 3. App lifecycle

- APP-1: The app runs as a menu bar item with no Dock icon.
- APP-2: The menu contains Launch at Login (toggle) and Quit. Launch at Login is hidden when the app runs outside a bundle (`swift run`).
- APP-3: On launch without Accessibility permission, the app shows the system permission prompt, and the menu shows "Waiting for Accessibility permission". It starts working as soon as permission is granted, with no restart.
- APP-4: Only one instance runs. A second launch, for example a manual launch on top of the login item, quits immediately.

## Known limitations

- The switcher only lists windows that the Accessibility API reports for the current Space.
- Secure input (password fields, Terminal's Secure Keyboard Entry) blocks the event tap. Shortcuts don't work while it is on.
- A hung app can stall the switcher and tiling for up to 0.5 s per AX call.
