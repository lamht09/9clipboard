# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · **简体中文** · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Mac 上的剪贴板历史记录。** 像平常一样拷贝，然后按 **⌥V**（Option‑V），就能找回之前拷贝过的任何内容——文本、带格式的文本或图片——并直接粘贴到你正在使用的 App 中。

免费、开源、注重隐私：历史记录只保存在你的 Mac 上。是 Paste 和 Maccy 的轻量替代品。

![9clipboard 演示：按 ⌥V 打开、搜索、筛选、预览、点按粘贴、把卡片拖到其他 App、固定](../assets/demo.gif)

▶ [观看完整演示视频（49 秒）](../assets/demo.mp4)

## 安装

需要搭载 Apple 芯片（M1 或更新）并运行 macOS 14 Sonoma 或更高版本的 Mac。

打开 **终端**（按 ⌘空格，输入“终端”，按 Enter），粘贴下面这行并按 Enter：

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

它会下载最新版本，确认是正版 App，放进“应用程序”文件夹并打开。

<details>
<summary>想自己下载？</summary>

1. 从 [Releases](https://github.com/lamht09/9clipboard/releases) 下载 `9clipboard-<版本>.zip`，解压后把 `9clipboard.app` 拖到“应用程序”文件夹。
2. 打开它。由于 9clipboard 没有在 Apple 登记，macOS 会提示无法验证此 App。前往 **系统设置 › 隐私与安全性**，点按 **仍要打开**。以这种方式下载的每个新版本都需要这样操作一次。

</details>

## 开始使用

1. 像平常一样拷贝一些内容。
2. 按 **⌥V**。历史记录会以一排卡片的形式出现在屏幕底部。
3. 点按一张卡片（或按 Enter），内容就会粘贴到你刚才使用的 App 中。

第一次使用时，macOS 会请求为 9clipboard 开启 **辅助功能** 权限，这样它才能替你按 ⌘V。请在 **系统设置 › 隐私与安全性 › 辅助功能** 中开启。不想开启也可以：点按卡片会拷贝内容，然后自己按 ⌘V，或者直接把卡片拖到另一个 App。

## 功能

- **快速查找。** 直接输入即可搜索。不必输入重音符号或完整单词：`cafe` 能找到“Café”。
- **按 ⇧Enter 粘贴为纯文本**，去掉格式。
- **拖放。** 把卡片拖到文稿、聊天窗口、备忘录或访达中。
- **保留常用内容。** 把卡片固定到 Pinboard；已固定的卡片永远不会被删除。
- **自动清理密码。** 从 1Password、“密码”等 App 拷贝的密码，如果不保留，15 分钟后会自动删除。
- **不打扰你。** 排除不想记录的 App，或从菜单栏暂停记录。
- **支持你的语言。** English、Tiếng Việt、简体中文、繁體中文、日本語、한국어、Español、Français、Deutsch、Português、Русский、Italiano。
- **自动更新**，在“设置 › 更新”中。

## 键盘快捷键

在面板中：

| 按键 | 操作 |
|---|---|
| 输入文字 | 搜索 |
| `←` `→` | 切换卡片 |
| `Enter` 或点按 | 粘贴 |
| `⇧Enter` | 粘贴为纯文本 |
| `⌘1` … `⌘9` | 粘贴第 1–9 张卡片 |
| `空格` | 大图预览 |
| `Tab` | 下一个筛选（全部、文本、图片…） |
| `⌘P` | 固定 |
| `⌘⌫` | 删除 |
| `Esc` | 关闭 |

要更改 ⌥V 或其他选项，请点按菜单栏中的 9clipboard 图标，选择 **设置…**。

## 隐私

- 历史记录只保存在你的 Mac 上。
- 9clipboard 唯一的联网操作是向 GitHub 查询最新版本号。不会发送任何关于你或你剪贴板的信息，并且可以在“设置 › 更新”中关闭。
- 辅助功能权限只用于替你按 ⌘V。

## 常见问题

**点按卡片后没有粘贴。**
查看“设置 › 权限”。如果没有辅助功能权限，请在“系统设置 › 隐私与安全性 › 辅助功能”中开启 9clipboard。

**如何更新？**
在“设置 › 更新”中更新，或再次运行安装命令。历史记录和设置都会保留。

**如何卸载？**
从菜单栏图标退出 9clipboard，然后把它从“应用程序”文件夹移到废纸篓。如果也想删除历史记录，请删除文件夹 `~/Library/Application Support/9clipboard`。

## 开发者

从源代码构建、运行测试和发布：请参阅 [CONTRIBUTING.md](../CONTRIBUTING.md)（英文）。

## 许可证

[MIT](../LICENSE)
