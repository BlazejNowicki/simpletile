# Spikes

Findings from throwaway experiments. Each entry states what was measured and the decision it led to.

## Focusing one window of another app (2026-11-21, macOS 27.2)

Setup: app A with windows A1 (left) and A2 (right), app B with window B over A2. B focused. A background process (not the active app) then focuses A1. Success means A is frontmost and B is still above A2. Six runs per method, checked through `NSWorkspace.frontmostApplication` and `CGWindowListCopyWindowInfo` z-order.

| Method | A frontmost | B above A2 |
|---|---|---|
| `AXMain` + `AXRaise`, `NSRunningApplication.activate()` | 0/6 | 6/6 |
| `AXMain` + `AXRaise`, app `AXFrontmost` | 6/6 | 0/6 |
| `AXFrontmost`, then `AXMain` + `AXRaise` | 6/6 | 0/6 |
| `AXMain` + `AXRaise`, `activate(options: .activateIgnoringOtherApps)` (deprecated) | 6/6 | 6/6 |
| `AXMain` + `AXRaise`, `NSApp.activate()`, `NSApp.yieldActivation(to:)`, `activate(from: .current)` | 6/6 | 6/6 |

- `activate()` from an inactive app is ignored: macOS 14 made activation cooperative.
- `AXFrontmost` activates like a Dock click and raises every window of the app.

Decision: raise the window, then hand activation over cooperatively (last row). It uses only non-deprecated public API.
