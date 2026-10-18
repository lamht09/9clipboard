# 9clipboard

**English** · [Tiếng Việt](README.vi.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) ![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-arm64-black) ![Swift 6](https://img.shields.io/badge/Swift-6-orange?logo=swift) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A free, open-source **clipboard manager for Mac** that keeps your **clipboard history** (text, rich text and images) private and offline — a lightweight alternative to Paste and Maccy, built natively in Swift/SwiftUI for macOS (Apple Silicon). Press **⌥V** to open a strip of cards at the bottom of the screen; pick a card and it is pasted straight into the app you are using.

![9clipboard demo: open with ⌥V, search without accents, drag a card into another app](assets/demo.gif)

▶ [Full demo video (49s)](assets/demo.mp4)

- Keeps text, rich text and images; fuzzy, accent-insensitive search (typing `da nang` finds “Đà Nẵng”)
- Pin items to Pinboards; pinned items are never deleted
- Passwords (from 1Password, Passwords…) are removed after 15 minutes; exclude apps, pause recording
- English and Vietnamese interface (follows your Mac’s language; change it in Settings › General)
- All data stays on your Mac — no network access

## Requirements

- macOS 14 or later on Apple Silicon (every Apple Silicon Mac, including M1, can update to macOS 14)
- To build from source: Swift 6 — the Command Line Tools are enough, no Xcode needed: `xcode-select --install`

## Install a release

### Quick install (recommended)

Paste this into Terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

It downloads the latest release, checks that it is signed with the 9clipboard release certificate, installs it to `/Applications` and opens it. Files downloaded by `curl` are not flagged by macOS, so there is **no Gatekeeper prompt**. Run the same command again to update. Then grant Accessibility access when asked (needed to paste with ⌘V).

### Manual install

1. Download `9clipboard-<version>.zip` from [Releases](https://github.com/lamht09/9clipboard/releases), unzip it and move `9clipboard.app` to `/Applications`.
2. Open it. The app is signed with a self-signed certificate, not notarized by Apple, so macOS blocks it the first time **every new version** is opened: go to System Settings › Privacy & Security › **Open Anyway**. Or skip that prompt by clearing the download flag before opening:
   ```sh
   xattr -dr com.apple.quarantine /Applications/9clipboard.app
   ```
3. Grant Accessibility access when asked (needed to paste with ⌘V). Every release is signed with the same certificate, so updating by replacing the app keeps this permission.

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

**Local builds are a separate app:** `make run` / `make install` produce **9clipboard Dev** (bundle ID `io.github.lamht09.9clipboard.dev`, data in `~/Library/Application Support/9clipboard-dev/`), so they never fight with an installed release over the Accessibility permission or the history.

**Releases** are built and signed by GitHub Actions when a `v*` tag is pushed; the signing job waits for manual approval in the `release` environment. One-time setup: `make release-cert` creates the certificate and stores it as environment secrets (see `.github/workflows/release.yml`).

## Permissions

On first launch the app asks for **Accessibility** permission so it can send ⌘V to the active app:

System Settings › Privacy & Security › Accessibility › enable **9clipboard** (or **9clipboard Dev** for a local build).

It still works without it: choosing a card copies its content and you press ⌘V yourself, or drag the card straight into the other app. Check the permission status under Settings › Permissions.

## Panel shortcuts

| Key | Action |
|---|---|
| type | Search |
| `←` `→` | Select a card |
| `Enter` / click | Paste |
| `⇧Enter` | Paste as plain text |
| `⌘1`…`⌘9` | Quick-paste card 1–9 |
| drag a card out of the panel | Drop its content where you release it (text field, Notes, Finder…); no Accessibility needed |
| `Space` | Large preview (when the search field is empty) |
| `Tab` / `⇧Tab` | Switch filter tab |
| `⌘P` | Pin to a Pinboard |
| `⌘⌫` | Delete card |
| `Esc` | Close preview → clear search → close panel |

Change the panel hotkey, history limit, launch at login and more from the menu bar › **Settings…** (⌘,).

## Data

`~/Library/Application Support/9clipboard/` (mode 0700): `clips.sqlite`, original images in `blobs/`, thumbnails in `thumbs/`. Deleting this folder wipes all history.

If you edit the database with `sqlite3`, always run `pragma foreign_keys=on;` first; otherwise orphaned rows are left behind and the app will fail to start.

## License

[MIT](LICENSE)
