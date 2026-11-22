# SimpleTile <img src="Resources/AppIcon.png" width="40%" align="right">

A small keyboard-driven window manager for macOS. It snaps windows to halves or full screen, and ⌥Tab switches between individual windows instead of apps.

## Install

```sh
brew install --cask blazejnowicki/tap/simpletile
```

SimpleTile needs the Accessibility permission to move and focus windows. It asks on first launch, and the permission persists across upgrades.

SimpleTile is signed with a self-signed certificate and is not notarized by Apple. The cask removes the `com.apple.quarantine` attribute, so the app opens without a Gatekeeper warning. Requires macOS 14 or later.

## Shortcuts

| Shortcut | Action |
|---|---|
| ⌥⌃← | Focused window to the left half |
| ⌥⌃→ | Focused window to the right half |
| ⌥⌃↑ | Focused window to the whole screen (not native fullscreen) |
| ⌥Tab | Open the window switcher. Tab, ⇧Tab, ← and → move the selection. Release ⌥ to switch, Esc to cancel. |

Tiling uses the display that holds most of the window, minus the menu bar and the Dock.

## Uninstall

```sh
brew uninstall --cask simpletile
```

## Build from source

```sh
swift test                  # core tests
swift run SimpleTile        # run from the terminal (the terminal needs Accessibility permission)
scripts/bundle.sh           # build/SimpleTile.app
scripts/install.sh          # build, install to ~/Applications, relaunch
```

Both scripts sign with `$SIMPLETILE_SIGN_IDENTITY` when set, otherwise ad hoc. With ad-hoc signing, macOS asks for the Accessibility permission again after every rebuild.

Design documents are in [`docs/`](docs/README.md).

## License

[MIT](LICENSE)
