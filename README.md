# 9clipboard

**English** · [Tiếng Việt](readme/README.vi.md) · [简体中文](readme/README.zh-Hans.md) · [繁體中文](readme/README.zh-Hant.md) · [日本語](readme/README.ja.md) · [한국어](readme/README.ko.md) · [Español](readme/README.es.md) · [Français](readme/README.fr.md) · [Deutsch](readme/README.de.md) · [Português](readme/README.pt-BR.md) · [Русский](readme/README.ru.md) · [Italiano](readme/README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**A clipboard history for your Mac.** Copy as usual, then press **⌥V** (Option‑V) to get back anything you copied earlier — text, formatted text or images — and paste it into the app you are using.

Free, open source and private: your history never leaves your Mac. A lightweight alternative to Paste and Maccy.

![9clipboard demo: open with ⌥V, search, filter, preview, click to paste, drag a card into another app, pin](assets/demo.gif)

▶ [Watch the full demo (49 seconds)](assets/demo.mp4)

## Install

You need a Mac with Apple Silicon (M1 or newer) running macOS 14 Sonoma or later.

Open **Terminal** (press ⌘Space, type “Terminal”, press Enter), paste this line and press Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

It downloads the latest version, checks that it is the genuine app, puts it in Applications and opens it.

<details>
<summary>Prefer to download it yourself?</summary>

1. Download `9clipboard-<version>.zip` from [Releases](https://github.com/lamht09/9clipboard/releases), unzip it and drag `9clipboard.app` into Applications.
2. Open it. macOS will say it can’t check the app, because 9clipboard isn’t registered with Apple. Go to **System Settings › Privacy & Security** and click **Open Anyway**. This happens once for each new version you download this way.

</details>

## Getting started

1. Copy a few things as you normally would.
2. Press **⌥V**. Your history appears as a row of cards at the bottom of the screen.
3. Click a card (or press Enter) and it is pasted into the app you were using.

The first time, macOS asks you to allow **Accessibility** for 9clipboard. This lets it press ⌘V for you. Turn it on in **System Settings › Privacy & Security › Accessibility**. If you’d rather not, 9clipboard still works: clicking a card copies it and you press ⌘V yourself, or you drag the card into the other app.

## What it does

- **Finds things fast.** Just start typing. You don’t need accents or whole words: `cafe` finds “Café”.
- **Finds Chinese, Japanese and Korean by sound.** Type pinyin, romaji or initial consonants: `beijing` finds “北京”, `tokyo` finds “東京タワー”, `ㅎㄱ` finds “한국”.
- **Pastes without formatting** when you press ⇧Enter.
- **Drag and drop.** Drag a card into a document, a chat, Notes or Finder.
- **Keeps what you reuse.** Pin cards to Pinboards; pinned cards are never deleted.
- **Cleans up passwords.** Passwords copied from 1Password, Passwords and similar apps are deleted after 15 minutes unless you keep them.
- **Stays out of the way.** Exclude apps you don’t want recorded, or pause recording from the menu bar.
- **Speaks your language.** English, Tiếng Việt, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch, Português, Русский, Italiano.
- **Updates itself** from Settings › Updates.

## Keyboard shortcuts

In the panel:

| Key | Action |
|---|---|
| Type | Search |
| `←` `→` | Move between cards |
| `Enter` or click | Paste |
| `⇧Enter` | Paste as plain text |
| `⌘1` … `⌘9` | Paste card 1–9 |
| `Space` | Large preview |
| `Tab` | Next filter (All, Text, Image…) |
| `⌘P` | Pin |
| `⌘⌫` | Delete |
| `Esc` | Close |

To change ⌥V and other options, click the 9clipboard icon in the menu bar and choose **Settings…**.

## Privacy

- Your history is stored only on your Mac.
- The only time 9clipboard goes online is to ask GitHub for the latest version number. Nothing about you or your clipboard is sent, and you can turn it off in Settings › Updates.
- Accessibility access is used only to press ⌘V for you.

## Questions

**Clicking a card doesn’t paste.**
Check Settings › Permissions. If Accessibility isn’t allowed, turn on 9clipboard in System Settings › Privacy & Security › Accessibility.

**How do I update?**
Settings › Updates, or run the install command again. Your history and settings are kept.

**How do I uninstall?**
Quit 9clipboard from its menu bar icon and move it from Applications to the Trash. To also delete your history, delete the folder `~/Library/Application Support/9clipboard`.

## For developers

Building from source, running tests and making releases: see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
