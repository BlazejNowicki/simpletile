# SimpleTile design documents

User documentation is in the [project README](../README.md).

## Idea

macOS has two gaps this project fills:

1. No quick keyboard tiling.
2. ⌘Tab switches applications, not windows.

## Principles

- Public APIs only. If a feature needs a private API, it is out of scope.
- One permission: Accessibility.
- Small and predictable. No automatic layouts. A window moves only when the user asks.

## Current state

Implemented: tiling (TIL-1 to TIL-6), the window switcher (SW-1 to SW-8), and the app lifecycle (APP-1 to APP-4). Tests exist for the core (L1). AX integration and end-to-end tests are not written yet.

## Documents

Written in order. Each phase is reviewed before the next starts.

| # | Document | Status |
|---|---|---|
| 1 | [Functionality](01-functionality.md) | Revised: workspaces, overlay and config removed |
| 2 | [Technology stack](02-technology-stack.md) | Revised |
| 3 | [Architecture and design](03-architecture.md) | Revised: describes the current code |
| 4 | [Test strategy](04-test-strategy.md) | Draft |
| 5 | [Implementation plan](05-implementation-plan.md) | Draft |
| 6 | [Distribution](06-distribution.md) | Draft |
