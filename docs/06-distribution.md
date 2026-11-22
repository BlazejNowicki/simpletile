# 6. Distribution: Homebrew cask in our own tap

Goal: `brew install --cask blazejnowicki/tap/simpletile` installs SimpleTile, and `brew upgrade` updates it.

## Constraints

Checked against Homebrew 7.0.13, installed on the development machine, and the Homebrew docs on 2026-11-21.

- Casks only download and copy a prebuilt app. They can't build from source. So every version needs a GitHub release with a zipped `SimpleTile.app`.
- Homebrew sets the quarantine attribute on everything a cask downloads, so Gatekeeper checks the app on first launch. The `--no-quarantine` flag no longer exists in 7.0 (`brew install --cask --help` doesn't list it).
- The requirement that casks pass Gatekeeper applies to the official `homebrew/cask` repository. Third-party taps are "unsupported" and aren't held to it, but Homebrew's stated direction is against bypassing Gatekeeper.
- `preflight` and `postflight` Ruby blocks are deprecated. Third-party taps get warnings until 11 December 2027. Their replacement is the declarative `postflight_steps` DSL, and its `run` step can call `/usr/bin/xattr` to remove the quarantine attribute. AeroSpace's cask does exactly this today (see [AeroSpace](#how-aerospace-does-it)). Homebrew's stated direction is against bypassing Gatekeeper, so this could be restricted for taps in a future release.
- Since Homebrew 6.0, non-official taps must be trusted explicitly. Installing by the fully qualified name, `brew install --cask blazejnowicki/tap/simpletile`, trusts just that cask.
- A public repository is the simple path. Taps and release downloads from private repositories need every user to set `HOMEBREW_GITHUB_API_TOKEN`.

## The signing decision

The tap mechanics are the same either way. What differs is what each user goes through.

| | Ad hoc | Self-signed certificate, cask removes quarantine | Developer ID, notarized |
|---|---|---|---|
| Cost | Free | Free | $99/year Apple Developer Program |
| First launch | Blocked. User clicks "Open Anyway" in System Settings → Privacy & Security. | Opens normally | Opens normally |
| After each `brew upgrade` | Gatekeeper again, and Accessibility must be granted again because the signature changed | Nothing. The certificate is the same, so the permission persists. | Nothing |
| Downloaded from the release page directly | Blocked | Blocked, "Open Anyway" needed | Opens normally |
| Extra CI work | None | Certificate as a repository secret, imported into a temporary keychain | Certificate and notarization credentials as secrets, plus a `notarytool` step |
| Risk | | Relies on Homebrew continuing to allow `xattr` in tap casks | None |

macOS ties the Accessibility permission to the app's designated requirement: its bundle identifier plus the signing certificate. With a self-signed certificate that requirement stays the same across builds, which is why the permission survives upgrades.

Plan: self-signed certificate plus quarantine removal in the cask, as AeroSpace does. Move to Developer ID if Homebrew stops allowing the `xattr` step, or if the app is to be offered as a direct download. Either change touches only the release workflow and the cask, not the app.

## Repositories

| Repository | Contents |
|---|---|
| `BlazejNowicki/simpletile` | This project. Releases hold `SimpleTile-<version>.zip`. |
| `BlazejNowicki/homebrew-tap` | `Casks/simpletile.rb`. The `homebrew-` prefix is what lets users write `blazejnowicki/tap`. |

## Changes to this project

1. Bundle identifier: `io.github.blazejnowicki.simpletile`. Changing it after the first release would reset every user's Accessibility permission and login item.
2. Version: `scripts/bundle.sh` writes `$VERSION` (default `0.0.0-dev`) into `CFBundleShortVersionString` and `$BUILD_NUMBER` (the CI run number in releases) into `CFBundleVersion`.
3. Universal binary: built with `--arch arm64 --arch x86_64`, so the app runs on Intel Macs too.
4. Packaging: `scripts/package.sh` runs `ditto -c -k --keepParent build/SimpleTile.app build/SimpleTile-$VERSION.zip`. `ditto` keeps the bundle's signature and extended attributes intact, which plain `zip` may not.

## Release workflow

`.github/workflows/release.yml`, triggered by pushing a tag `v*`:

1. Check out the code on a macOS runner.
2. Run `swift test`.
3. Import the self-signed certificate (`.p12` and its password, stored as secrets) into a temporary keychain, then run `VERSION=${tag#v} BUILD_NUMBER=$GITHUB_RUN_NUMBER SIMPLETILE_SIGN_IDENTITY="Simple Tile Release" scripts/bundle.sh`.
4. Zip it and compute the `sha256`.
5. Create the GitHub release with the zip attached.
6. Update `Casks/simpletile.rb` in the tap (version and `sha256`) and push. This needs a fine-grained token with write access to the tap repository, stored as a secret.

Releasing becomes `git tag v0.2.0 && git push --tags`.

## The cask

```ruby
cask "simpletile" do
  version "0.1.0"
  sha256 "<sha256 of the zip>"

  url "https://github.com/BlazejNowicki/simpletile/releases/download/v#{version}/SimpleTile-#{version}.zip"
  name "SimpleTile"
  desc "Keyboard window tiling and a per-window switcher"
  homepage "https://github.com/BlazejNowicki/simpletile"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "SimpleTile.app"

  # The app is self-signed, not notarized: without this, Gatekeeper blocks the first launch.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", "{{appdir}}/SimpleTile.app"], must_succeed: false
  end

  uninstall quit: "io.github.blazejnowicki.simpletile"
end
```

Before publishing, check it with `brew audit --cask --online --strict` and `brew style`, using the tap's own checkout.

## User instructions (README)

```sh
brew install --cask blazejnowicki/tap/simpletile
```

Then grant Accessibility once. It persists across upgrades. The README also states that the app is not notarized and that the cask removes the quarantine attribute, as AeroSpace's README does.

## How AeroSpace does it

Checked on 2026-11-21: AeroSpace commit `6ed6af6` and `nikitabobko/homebrew-tap` `Casks/aerospace.rb`.

- Installed with `brew install --cask nikitabobko/tap/aerospace`, from the author's own tap.
- Not notarized and no Developer ID. The README says so explicitly.
- Releases are signed with a self-signed certificate named `aerospace-codesign-certificate` (`build-release.sh`). CI builds sign ad hoc and only validate.
- The cask, generated by `build-brew-cask.sh`, removes quarantine in `postflight_steps` with `run "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", ...], must_succeed: false`.

One difference: AeroSpace builds releases on the author's machine, where the certificate lives. This plan signs in CI instead, so releases don't depend on one laptop.

## Steps

See [Implementation plan](05-implementation-plan.md), steps 7 to 11.

## Not covered

- Official `homebrew/cask`: requires a signed, notarized app and some popularity.
- A Homebrew formula that builds from source: it would avoid Gatekeeper, since locally built apps aren't quarantined, but formulas are meant for command-line tools, and it installs the app under the Homebrew prefix, not `/Applications`.
- Sparkle in-app updates: unnecessary for Homebrew users.
