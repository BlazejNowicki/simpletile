# 5. Implementation plan: first public release

Steps from the current code to `brew install --cask blazejnowicki/tap/simpletile`. Each step is one session: it lists what to change, how to verify it, and who acts. A step is done when every check under "Verify" passes and the user has reviewed the result.

To run a step in a new session: "Execute step N of `docs/05-implementation-plan.md`."

Fixed decisions:

| | |
|---|---|
| GitHub account | `BlazejNowicki` |
| Repositories | `BlazejNowicki/simpletile` (public), `BlazejNowicki/homebrew-tap` (public) |
| Bundle identifier | `io.github.blazejnowicki.simpletile` |
| License | MIT. Permissive, the shortest common license, and what AeroSpace uses. |
| Signing | Self-signed certificate `Simple Tile Release`, no notarization. See [Distribution](06-distribution.md). |
| Releases | Built and signed in GitHub Actions on a `v*` tag |

## Step 1: Repository hygiene

Status: done 2026-11-22, awaiting review.

Who: Claude.

Changes:
- `.gitignore`: add `.idea/`, `.DS_Store`, `.swiftpm/`.
- Delete the stale `build/WindowManager.app`.
- Rename `$WM_SIGN_IDENTITY` to `$SIMPLETILE_SIGN_IDENTITY` in `scripts/` and `docs/`.
- `LICENSE`: MIT, `Copyright (c) 2026 Blazej Nowicki`.
- Root `README.md` for users: what it does, install command, shortcuts table, Accessibility permission, the note that the app is not notarized and the cask removes the quarantine attribute, uninstall, build from source, link to `docs/`.
- `docs/README.md`: design index only. Build commands move to the root README.

Verify:
- `swift test` passes.
- `grep -r WM_SIGN_IDENTITY .` finds nothing outside `.build/` and this plan.
- `SIMPLETILE_SIGN_IDENTITY=<your cert> scripts/install.sh` installs and the app runs.

## Step 2: Git and GitHub

Status: done 2026-11-22. Commits use the GitHub noreply email, set in the repository config.

Who: Claude, with the user approving the push.

Changes:
- `git init`, branch `main`, one initial commit.
- `gh repo create BlazejNowicki/simpletile --public --source . --push`.

Verify:
- `git status` is clean, and `git ls-files` lists no `.idea/`, `build/` or `.build/` paths.
- `gh repo view BlazejNowicki/simpletile` shows the README and the MIT license.

## Step 3: Formatting and traceability

Status: done 2026-11-22, awaiting review.

Who: Claude.

Changes:
- `.swift-format`: line length 120, 4-space indent, matching the current code.
- `swift format --in-place --recursive Sources Tests`, committed separately so the diff is reviewable.
- `scripts/check-traceability.sh`: extracts every requirement ID from `docs/01-functionality.md` and fails, naming the ID, if one appears in no `@Test` name and no `M-` item of `docs/04-test-strategy.md`.

Verify:
- `swift format lint --strict --recursive Sources Tests` exits 0.
- `scripts/check-traceability.sh` exits 0.
- Renaming the `SW-7` test temporarily makes the script fail and name `SW-7`.

## Step 4: Split `AppDelegate`

Status: code done 2026-11-22. Manual check on the installed app pending.

Who: Claude. Behaviour is unchanged, so no requirement or test changes.

Changes:
- `SwitcherController`: switcher state, session counter, 100 ms show delay, open, next, previous, commit, cancel.
- `StatusMenu`: status item, permission item, Launch at Login, Quit.
- `AppDelegate`: single-instance check, permission polling, wiring.
- Update the AppDelegate section of `docs/03-architecture.md`.

Verify:
- `swift test` passes, `swift build` has no warnings.
- Manual, on the installed app: ⌥Tab with 1 and 3 windows, ⌥Tab quick release, Esc, ⌥⌃← ⌥⌃→ ⌥⌃↑, Launch at Login toggles, Quit.

## Step 5: CI

Status: done 2026-11-22. Green run on `main`, red run on the closed PR #1.

Who: Claude.

Changes:
- `.github/workflows/ci.yml` on push and pull request to `main`, `macos-26` runner: `swift build`, `swift test --enable-code-coverage`, `scripts/check-coverage.sh 90` (line coverage of `SimpleTileCore` from the SwiftPM coverage JSON), `scripts/check-traceability.sh`, `swift format lint --strict`, `scripts/bundle.sh` signed ad hoc.

Verify:
- `gh run watch` on the push shows the run green.
- A draft pull request with a deliberately failing test shows the run red. Close it and delete the branch after.

## Step 6: App icon and Info.plist

Status: done 2026-11-22, awaiting review.

Who: the user generates the image with the prompt below; Claude does the rest.

Changes:
- `Resources/AppIcon.png`, 1024 × 1024. `scripts/bundle.sh` builds `AppIcon.icns` from it with `sips` and `iconutil`, so the PNG is the only source.
- `Info.plist`: `CFBundleIconFile = AppIcon`, `NSHumanReadableCopyright = Copyright © 2026 Blazej Nowicki. MIT License.`

Verify:
- `plutil -lint Resources/Info.plist` passes.
- The built app shows the icon in Finder and in System Settings → Privacy & Security → Accessibility.
- The icon is recognisable at 16 × 16 (Finder list view).

Prompt for the image generator:

> A macOS app icon for "SimpleTile", a minimal keyboard-driven window tiling utility. 1024 × 1024 px, in the current macOS app icon style: a single rounded-square (squircle) tile, 824 × 824 px, centred on a transparent canvas, with a soft drop shadow below it. Background of the tile: a smooth vertical gradient from deep blue (#2F5BEA) at the top to indigo (#3A2E9C) at the bottom. On the tile, two tall rounded rectangles side by side, like a screen split into a left and a right half, separated by a narrow gap and inset evenly from the tile's edges. The panes are white with a subtle frosted-glass look; the left pane is fully opaque and the right one slightly translucent, suggesting a window snapped to the left half. Each pane has a thin title bar strip along its top edge. Flat, clean, geometric, high contrast, centred, no text, no letters, no cursor, no keyboard, no Apple logos. It must stay readable at 16 × 16 px.

The menu bar uses the SF Symbol `rectangle.split.2x1`. The icon only borrows the idea: Apple's SF Symbols license does not allow symbols in app icons.

## Step 7: Release build

Status: done 2026-11-22, awaiting review.

Who: Claude.

Changes:
- `Resources/Info.plist`: bundle identifier `io.github.blazejnowicki.simpletile`.
- `scripts/bundle.sh`: writes `$VERSION` (default `0.0.0-dev`) to `CFBundleShortVersionString` and `$BUILD_NUMBER` (default `1`) to `CFBundleVersion` with `PlistBuddy`, builds with `--arch arm64 --arch x86_64`.
- `scripts/package.sh`: `ditto -c -k --keepParent build/SimpleTile.app build/SimpleTile-$VERSION.zip`, prints the `sha256`.
- Update `docs/02-technology-stack.md` and `docs/06-distribution.md` where they describe the scripts.

Verify:
- `lipo -archs build/SimpleTile.app/Contents/MacOS/SimpleTile` prints `x86_64 arm64`.
- `VERSION=0.1.0 scripts/bundle.sh`, then `plutil -extract CFBundleShortVersionString raw build/SimpleTile.app/Contents/Info.plist` prints `0.1.0`.
- `unzip -l` on the zip shows `SimpleTile.app/` at the top level.

The new bundle identifier resets the local Accessibility permission and login item once. Grant them again after installing.

## Step 8: Release certificate

Status: done 2026-11-22. The certificate is named `Simple Tile Release` (with a space); its SHA-1 is `BB7EF8C00D0450A7E390EED4AAF072626E68DA6F`. Both secrets are set.

Who: the user, with Claude guiding.

Changes:
- Keychain Access → Certificate Assistant → Create a Certificate: name `Simple Tile Release`, identity type Self-Signed Root, certificate type Code Signing, validity 3650 days.
- Export it with its private key as `SimpleTile-Release.p12`, with a password. Store the file and password in a password manager, not in the repository.
- `gh secret set SIGNING_CERT_P12 < <(base64 -i SimpleTile-Release.p12)` and `gh secret set SIGNING_CERT_PASSWORD`.

Verify:
- `security find-identity -p codesigning` lists `Simple Tile Release`.
- The CI flow works locally: import the `.p12` into a new temporary keychain, sign `build/SimpleTile.app` with it, and `codesign -dv --verbose=2` shows `Authority=Simple Tile Release`. If `codesign` rejects the untrusted certificate, the release workflow needs a trust step; record the fix in `docs/spikes.md`.
- `gh secret list` shows both secrets.

## Step 9: Release workflow

Who: Claude, with the user approving the tag push.

Changes:
- `.github/workflows/release.yml` on tag `v*`: test, import the certificate into a temporary keychain, `VERSION=${tag#v} BUILD_NUMBER=$GITHUB_RUN_NUMBER SIMPLETILE_SIGN_IDENTITY="Simple Tile Release" scripts/bundle.sh`, `scripts/package.sh`, `gh release create` with the zip.
- A manual run (`gh workflow run release.yml`) builds and signs without publishing, and uploads the zip as an artifact.
- Tag and push `v0.1.0`.

Verify:
- A manual run is green, including the `Authority=Simple Tile Release` check.
- `gh release view v0.1.0` lists `SimpleTile-0.1.0.zip`.
- The downloaded zip, unpacked: `codesign -dv` shows `Authority=Simple Tile Release`, and `lipo -archs` shows both architectures.

## Step 10: Tap and cask

Who: Claude, with the user approving the repository creation.

Changes:
- `gh repo create BlazejNowicki/homebrew-tap --public`, with a README.
- `scripts/cask.sh VERSION SHA256` prints `Casks/simpletile.rb` from the template in [Distribution](06-distribution.md). Run it for `0.1.0` and commit the result to the tap by hand.

Verify:
- `brew audit --cask --online --strict blazejnowicki/tap/simpletile` and `brew style` pass.
- `brew install --cask blazejnowicki/tap/simpletile` installs to `/Applications`, the app opens with no Gatekeeper prompt, and `xattr /Applications/SimpleTile.app` lists no `com.apple.quarantine`.
- Grant Accessibility, and the shortcuts work.

## Step 11: Automatic tap update

Who: Claude; the user creates the token.

Changes:
- The user creates a fine-grained token with contents write access to `BlazejNowicki/homebrew-tap` only, stored as the `TAP_TOKEN` secret.
- `release.yml`: after the release, run `scripts/cask.sh` and push the cask to the tap.
- Tag and push `v0.1.1`.

Verify:
- The tap's history has a commit for `0.1.1` made by the workflow.
- `brew upgrade --cask simpletile` installs `0.1.1`, and the shortcuts work without granting Accessibility again.
