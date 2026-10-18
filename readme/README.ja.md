# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · **日本語** · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Mac のためのクリップボード履歴。** いつも通りにコピーして、**⌥V**（Option‑V）を押すだけ。以前コピーしたテキスト、書式付きテキスト、画像を呼び出して、使っているアプリにそのままペーストできます。

無料、オープンソース、プライバシー重視：履歴はあなたの Mac から外に出ません。Paste や Maccy の軽量な代わりとして使えます。

![9clipboard のデモ：⌥V で開く、検索、フィルタ、プレビュー、クリックでペースト、カードを別のアプリにドラッグ、ピン留め](../assets/demo.gif)

▶ [デモ動画をすべて見る（49秒）](../assets/demo.mp4)

## インストール

Apple シリコン（M1 以降）搭載で、macOS 14 Sonoma 以降の Mac が必要です。

**ターミナル** を開き（⌘スペースを押して「ターミナル」と入力し Enter）、次の行をペーストして Enter を押します：

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

最新版をダウンロードし、正規のアプリであることを確認してから、アプリケーションフォルダに入れて起動します。

<details>
<summary>自分でダウンロードしたい場合</summary>

1. [Releases](https://github.com/lamht09/9clipboard/releases) から `9clipboard-<バージョン>.zip` をダウンロードして展開し、`9clipboard.app` をアプリケーションフォルダにドラッグします。
2. 起動します。9clipboard は Apple に登録されていないため、macOS はアプリを確認できないと表示します。**システム設定 › プライバシーとセキュリティ** で **このまま開く** をクリックしてください。この方法でダウンロードした新しいバージョンごとに一度必要です。

</details>

## 使い方

1. いつも通りにいくつかコピーします。
2. **⌥V** を押します。画面の下に履歴がカードとして並びます。
3. カードをクリック（または Enter）すると、直前まで使っていたアプリにペーストされます。

初回は、9clipboard に **アクセシビリティ** を許可するよう macOS から求められます。これは 9clipboard があなたの代わりに ⌘V を押すためです。**システム設定 › プライバシーとセキュリティ › アクセシビリティ** でオンにしてください。許可しなくても使えます：カードをクリックするとコピーされるので自分で ⌘V を押すか、カードを別のアプリにドラッグします。

## できること

- **すばやく見つかる。** 入力するだけで検索。アクセント記号や単語全体を入力しなくても大丈夫：`cafe` で「Café」が見つかります。
- **ローマ字でも検索。** `tokyo` で「東京タワー」が見つかります。ひらがなとカタカナも区別しません。中国語はピンイン（`beijing` →「北京」）、韓国語は初声（`ㅎㄱ` →「한국」）でも検索できます。
- **⇧Enter で書式なしペースト。**
- **ドラッグ＆ドロップ。** カードを書類、チャット、メモ、Finder にドラッグできます。
- **よく使うものを残す。** カードを Pinboard にピン留め。ピン留めしたカードは削除されません。
- **パスワードを自動で片付け。** 1Password や“パスワード”などからコピーしたパスワードは、残さない限り15分後に削除されます。
- **邪魔をしない。** 記録したくないアプリを除外したり、メニューバーから記録を一時停止したりできます。
- **あなたの言語で。** English、Tiếng Việt、简体中文、繁體中文、日本語、한국어、Español、Français、Deutsch、Português、Русский、Italiano。
- **自動アップデート**（設定 › アップデート）。

## キーボードショートカット

パネル内で：

| キー | 操作 |
|---|---|
| 文字を入力 | 検索 |
| `←` `→` | カードを移動 |
| `Enter` またはクリック | ペースト |
| `⇧Enter` | プレーンテキストとしてペースト |
| `⌘1` … `⌘9` | 1〜9番目のカードをペースト |
| `スペース` | 大きくプレビュー |
| `Tab` | 次のフィルタ（すべて、テキスト、画像…） |
| `⌘P` | ピン留め |
| `⌘⌫` | 削除 |
| `Esc` | 閉じる |

⌥V などの設定を変えるには、メニューバーの 9clipboard アイコンをクリックして **設定…** を選びます。

## プライバシー

- 履歴はあなたの Mac にだけ保存されます。
- 9clipboard がネットに接続するのは、GitHub に最新のバージョン番号を問い合わせるときだけです。あなたやクリップボードに関する情報は送信されず、設定 › アップデートでオフにできます。
- アクセシビリティへのアクセスは、⌘V を押すためだけに使われます。

## よくある質問

**カードをクリックしてもペーストされない。**
設定 › アクセス権を確認してください。アクセシビリティが許可されていなければ、システム設定 › プライバシーとセキュリティ › アクセシビリティで 9clipboard をオンにします。

**アップデートするには？**
設定 › アップデートから、またはインストールのコマンドをもう一度実行します。履歴と設定はそのまま残ります。

**アンインストールするには？**
メニューバーのアイコンから 9clipboard を終了し、アプリケーションフォルダからゴミ箱に入れます。履歴も消したい場合は、フォルダ `~/Library/Application Support/9clipboard` を削除してください。

## 開発者向け

ソースからのビルド、テスト、リリースについては [CONTRIBUTING.md](../CONTRIBUTING.md)（英語）をご覧ください。

## ライセンス

[MIT](../LICENSE)
