# Building 9clipboard

## Requirements

- macOS 14 or later on Apple Silicon
- Swift 6. The Command Line Tools are enough, no Xcode needed: `xcode-select --install`

## Build and install

Clone the repo, then:

```sh
make cert      # once: creates a self-signed "9clipboard Dev" certificate in your Keychain
make install   # builds release, signs, copies to /Applications/9clipboard-dev.app and launches it
```

Other commands:

| Command | What it does |
|---|---|
| `make run` | Build, sign and run from `build/9clipboard-dev.app` |
| `make test` | Run the `ClipCore` unit tests (don't use plain `swift test`: with only the Command Line Tools it sometimes fails to load the `TestingMacros` plugin) |
| `make bench` | Benchmark search over 2,000 items in a release build (target < 10 ms) |
| `scripts/make-icon.sh` | Redraw `Resources/AppIcon.icns` |

**Why a self-signed certificate:** macOS remembers the Accessibility permission by the app's signature. With ad-hoc signing every build gets a new signature and the permission is lost; signing with the same certificate keeps it.

**Local builds are a separate app:** `make run` / `make install` produce **9clipboard Dev** (bundle ID `io.github.lamht09.9clipboard.dev`, data in `~/Library/Application Support/9clipboard-dev/`), so they never fight with an installed release over the Accessibility permission or the history. Grant Accessibility to **9clipboard Dev** separately.

## Translations

Interface strings live in `Resources/<language>.lproj/Localizable.strings`; the key is the English sentence used in the code. Plural forms go in `Localizable.stringsdict` (English and languages whose words change with the number). To add a language, add its folder, list it under `CFBundleLocalizations` in `Resources/Info.plist`, and add a case to `AppLanguage`.

## Data

`~/Library/Application Support/9clipboard/` (mode 0700): `clips.sqlite`, original images in `blobs/`, thumbnails in `thumbs/`.

If you edit the database with `sqlite3`, always run `pragma foreign_keys=on;` first; otherwise orphaned rows are left behind and the app will fail to start.

## Installing a release without the Gatekeeper prompt

Releases are signed with a self-signed certificate and not notarized, so a downloaded zip is blocked on first open. `install.sh` avoids this because files downloaded by `curl` are not quarantined. For a manually downloaded copy you can clear the flag instead:

```sh
xattr -dr com.apple.quarantine /Applications/9clipboard.app
```

Every release is signed with the same certificate, so replacing the app keeps the Accessibility permission.

## Releases

Releases are built and signed by GitHub Actions when a `v*` tag is pushed; the signing job waits for manual approval in the `release` environment. One-time setup: `make release-cert` creates the certificate and stores it as environment secrets (see `.github/workflows/release.yml`).
