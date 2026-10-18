# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · **繁體中文** · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Mac 上的剪貼簿歷史記錄。** 像平常一樣拷貝，然後按下 **⌥V**（Option‑V），就能找回之前拷貝過的任何內容——文字、格式化文字或影像——並直接貼到你正在使用的 App 中。

免費、開放原始碼、重視隱私：歷史記錄只保存在你的 Mac 上。是 Paste 和 Maccy 的輕量替代方案。

![9clipboard 示範：按下 ⌥V 打開、搜尋、篩選、預覽、按一下貼上、把卡片拖到其他 App、釘選](../assets/demo.gif)

▶ [觀看完整示範影片（49 秒）](../assets/demo.mp4)

## 安裝

需要搭載 Apple 晶片（M1 或更新）並執行 macOS 14 Sonoma 或以上版本的 Mac。

打開 **終端機**（按下 ⌘空白鍵，輸入「終端機」，按 Enter），貼上下面這行並按 Enter：

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

它會下載最新版本，確認是正版 App，放進「應用程式」檔案夾並打開。

<details>
<summary>想自己下載？</summary>

1. 從 [Releases](https://github.com/lamht09/9clipboard/releases) 下載 `9clipboard-<版本>.zip`，解壓縮後把 `9clipboard.app` 拖到「應用程式」檔案夾。
2. 打開它。由於 9clipboard 沒有向 Apple 登記，macOS 會提示無法驗證此 App。前往 **系統設定 › 隱私權與安全性**，按一下 **強制打開**。以這種方式下載的每個新版本都需要這樣操作一次。

</details>

## 開始使用

1. 像平常一樣拷貝一些內容。
2. 按下 **⌥V**。歷史記錄會以一排卡片的形式出現在螢幕底部。
3. 按一下卡片（或按 Enter），內容就會貼到你剛才使用的 App 中。

第一次使用時，macOS 會要求為 9clipboard 開啟 **輔助使用** 權限，這樣它才能替你按下 ⌘V。請在 **系統設定 › 隱私權與安全性 › 輔助使用** 中開啟。不想開啟也可以：按一下卡片會拷貝內容，再自行按下 ⌘V，或直接把卡片拖到另一個 App。

## 功能

- **快速尋找。** 直接輸入即可搜尋。不必輸入重音符號或完整單字：`cafe` 能找到「Café」。
- **用拼音尋找。** 輸入拼音或拼音首字母即可：`beijing` 或 `bj` 都能找到「北京」。日文可用羅馬字（`tokyo` → 「東京タワー」），韓文可用初聲（`ㅎㄱ` → 「한국」）。
- **按下 ⇧Enter 貼上為純文字**，去除格式。
- **拖放。** 把卡片拖到文件、聊天視窗、備忘錄或 Finder。
- **保留常用內容。** 把卡片釘選到 Pinboard；已釘選的卡片永遠不會被刪除。
- **自動清除密碼。** 從 1Password、「密碼」等 App 拷貝的密碼，若不保留，15 分鐘後會自動刪除。
- **不打擾你。** 排除不想記錄的 App，或從選單列暫停記錄。
- **支援你的語言。** English、Tiếng Việt、简体中文、繁體中文、日本語、한국어、Español、Français、Deutsch、Português、Русский、Italiano。
- **自動更新**，在「設定 › 更新」中。

## 鍵盤快速鍵

在面板中：

| 按鍵 | 動作 |
|---|---|
| 輸入文字 | 搜尋 |
| `←` `→` | 切換卡片 |
| `Enter` 或按一下 | 貼上 |
| `⇧Enter` | 貼上為純文字 |
| `⌘1` … `⌘9` | 貼上第 1–9 張卡片 |
| `空白鍵` | 大型預覽 |
| `Tab` | 下一個篩選（全部、文字、影像⋯） |
| `⌘P` | 釘選 |
| `⌘⌫` | 刪除 |
| `Esc` | 關閉 |

若要更改 ⌥V 或其他選項，請按一下選單列中的 9clipboard 圖像，選擇 **設定⋯**。

## 隱私權

- 歷史記錄只保存在你的 Mac 上。
- 9clipboard 唯一的連網動作是向 GitHub 查詢最新版本號碼。不會傳送任何關於你或你剪貼簿的資訊，並可在「設定 › 更新」中關閉。
- 輔助使用權限只用來替你按下 ⌘V。

## 常見問題

**按一下卡片後沒有貼上。**
查看「設定 › 權限」。若沒有輔助使用權限，請在「系統設定 › 隱私權與安全性 › 輔助使用」中開啟 9clipboard。

**如何更新？**
在「設定 › 更新」中更新，或再次執行安裝指令。歷史記錄和設定都會保留。

**如何解除安裝？**
從選單列圖像結束 9clipboard，然後把它從「應用程式」檔案夾移到垃圾桶。若也想刪除歷史記錄，請刪除檔案夾 `~/Library/Application Support/9clipboard`。

## 開發者

從原始碼建置、執行測試和發佈：請參閱 [CONTRIBUTING.md](../CONTRIBUTING.md)（英文）。

## 授權

[MIT](../LICENSE)
