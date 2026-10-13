# 9clipboard

**English** · [Tiếng Việt](README.vi.md)

A clipboard history manager for macOS (Apple Silicon). Press **⌥V** to open a strip of cards at the bottom of the screen; pick a card and it is pasted straight into the app you are using.

- Keeps text, rich text and images; fuzzy, accent-insensitive search (typing `da nang` finds “Đà Nẵng”)
- Pin items to Pinboards; pinned items are never deleted
- Passwords (from 1Password, Passwords…) are removed after 15 minutes; exclude apps, pause recording
- All data stays on your Mac — no network access

Docs (in Vietnamese): [design](docs/DESIGN.md) · [plan](docs/PLAN.md) · [status](docs/STATE.md)

## Requirements

- macOS 14 or later on Apple Silicon (every Apple Silicon Mac, including M1, can update to macOS 14)
- Swift 6 — the Command Line Tools are enough, no Xcode needed: `xcode-select --install`

## Build and install

Clone the repo, then:

```sh
make cert      # once: creates a self-signed "9clipboard Dev" certificate in your Keychain
make install   # builds release, signs, copies to /Applications and launches the app
```

Other commands:

| Command | What it does |
|---|---|
| `make run` | Build, sign and run from `build/9clipboard.app` |
| `make test` | Run the `ClipCore` unit tests (don't use plain `swift test`, see `docs/STATE.md`) |
| `make bench` | Benchmark search over 2,000 items in a release build (target < 10 ms) |
| `scripts/make-icon.sh` | Redraw `Resources/AppIcon.icns` |

**Why a self-signed certificate:** macOS remembers the Accessibility permission by the app's signature. With ad-hoc signing every build gets a new signature and the permission is lost; signing with the same certificate keeps it.

## Permissions

On first launch the app asks for **Accessibility** permission so it can send ⌘V to the active app:

System Settings › Privacy & Security › Accessibility › enable **9clipboard**.

It still works without it: choosing a card copies its content and you press ⌘V yourself. Check the permission status under Settings › Permissions.

## Panel shortcuts

| Key | Action |
|---|---|
| type | Search |
| `←` `→` | Select a card |
| `Enter` / click | Paste |
| `⇧Enter` | Paste as plain text |
| `⌘1`…`⌘9` | Quick-paste card 1–9 |
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
