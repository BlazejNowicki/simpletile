# 5. Releasing

```sh
git tag -a v0.2.0 -m "SimpleTile 0.2.0" && git push origin v0.2.0
```

`.github/workflows/release.yml` then tests, builds and signs the app, publishes `SimpleTile-<version>.zip` as a GitHub release, and pushes the regenerated cask to [`BlazejNowicki/homebrew-tap`](https://github.com/BlazejNowicki/homebrew-tap). Users get it with `brew upgrade`. A manual run of the workflow does everything except publishing, and uploads the zip as an artifact.

## Signing

The app is signed with a self-signed certificate and is not notarized, as AeroSpace does. The cask removes the `com.apple.quarantine` attribute after install, so Gatekeeper doesn't block the first launch.

| | |
|---|---|
| Certificate | `Simple Tile Release`, SHA-1 `BB7EF8C00D0450A7E390EED4AAF072626E68DA6F`, valid until 2036-11-19 |
| Bundle identifier | `io.github.blazejnowicki.simpletile` |
| Backup | The `.p12` and its password, in the password manager |

macOS ties the Accessibility permission to the bundle identifier plus the certificate's hash. Never change the bundle identifier or create a new certificate: every user would have to grant Accessibility again.

## Secrets of `BlazejNowicki/simpletile`

| Secret | Holds |
|---|---|
| `SIGNING_CERT_P12` | The certificate and private key, base64 |
| `SIGNING_CERT_PASSWORD` | The `.p12` password |
| `TAP_DEPLOY_KEY` | Private half of the write deploy key on `homebrew-tap` |

## Constraints

- Homebrew casks only install prebuilt apps, so every version needs a release zip.
- Removing quarantine through `postflight_steps` works for third-party taps today. If Homebrew restricts it, the fallback is a Developer ID certificate and notarization ($99 per year), which changes only the workflow and the cask.
- The official `homebrew/cask` repository requires a notarized app.
