# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · **한국어** · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Mac을 위한 클립보드 기록.** 평소처럼 복사한 다음 **⌥V**(Option‑V)를 누르면, 이전에 복사한 텍스트, 서식 있는 텍스트, 이미지를 다시 불러와 사용 중인 앱에 바로 붙여넣을 수 있습니다.

무료, 오픈 소스, 개인정보 보호: 기록은 사용자의 Mac 밖으로 나가지 않습니다. Paste와 Maccy를 대신할 가벼운 앱입니다.

![9clipboard 데모: ⌥V로 열기, 검색, 필터, 미리보기, 클릭하여 붙여넣기, 카드를 다른 앱으로 드래그, 고정](../assets/demo.gif)

▶ [전체 데모 영상 보기(49초)](../assets/demo.mp4)

## 설치

Apple 실리콘(M1 이상)을 탑재하고 macOS 14 Sonoma 이상을 실행하는 Mac이 필요합니다.

**터미널**을 열고(⌘스페이스를 누르고 '터미널' 입력 후 Enter) 아래 줄을 붙여넣은 다음 Enter를 누르십시오.

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

최신 버전을 다운로드하고, 정품 앱인지 확인한 다음 응용 프로그램 폴더에 넣고 실행합니다.

<details>
<summary>직접 다운로드하려면</summary>

1. [Releases](https://github.com/lamht09/9clipboard/releases)에서 `9clipboard-<버전>.zip`을 다운로드하여 압축을 풀고 `9clipboard.app`을 응용 프로그램 폴더로 드래그합니다.
2. 앱을 엽니다. 9clipboard는 Apple에 등록되어 있지 않아 macOS가 앱을 확인할 수 없다고 표시합니다. **시스템 설정 › 개인정보 보호 및 보안**에서 **그래도 열기**를 클릭하십시오. 이 방법으로 다운로드한 새 버전마다 한 번씩 필요합니다.

</details>

## 시작하기

1. 평소처럼 몇 가지를 복사합니다.
2. **⌥V**를 누릅니다. 화면 아래에 기록이 카드 형태로 나타납니다.
3. 카드를 클릭하거나 Enter를 누르면 방금 사용하던 앱에 붙여넣어집니다.

처음 사용할 때 macOS가 9clipboard에 **손쉬운 사용** 권한을 허용할지 묻습니다. 9clipboard가 대신 ⌘V를 누르기 위해 필요합니다. **시스템 설정 › 개인정보 보호 및 보안 › 손쉬운 사용**에서 켜십시오. 허용하지 않아도 사용할 수 있습니다. 카드를 클릭하면 복사되므로 직접 ⌘V를 누르거나, 카드를 다른 앱으로 드래그하면 됩니다.

## 기능

- **빠른 검색.** 입력하면 바로 검색됩니다. 악센트 기호나 단어 전체를 입력할 필요가 없습니다. `cafe`로 'Café'를 찾을 수 있습니다.
- **⇧Enter로 서식 없이 붙여넣기.**
- **드래그 앤 드롭.** 카드를 문서, 채팅, 메모, Finder로 드래그할 수 있습니다.
- **자주 쓰는 항목 보관.** 카드를 Pinboard에 고정하십시오. 고정한 카드는 절대 삭제되지 않습니다.
- **암호 자동 정리.** 1Password, 암호 등에서 복사한 암호는 유지하지 않으면 15분 후 삭제됩니다.
- **방해하지 않음.** 기록하고 싶지 않은 앱을 제외하거나 메뉴 막대에서 기록을 일시 정지할 수 있습니다.
- **사용자의 언어로.** English, Tiếng Việt, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch, Português, Русский, Italiano.
- **자동 업데이트**(설정 › 업데이트).

## 키보드 단축키

패널에서:

| 키 | 동작 |
|---|---|
| 글자 입력 | 검색 |
| `←` `→` | 카드 이동 |
| `Enter` 또는 클릭 | 붙여넣기 |
| `⇧Enter` | 일반 텍스트로 붙여넣기 |
| `⌘1` … `⌘9` | 1–9번째 카드 붙여넣기 |
| `스페이스` | 크게 미리보기 |
| `Tab` | 다음 필터(전체, 텍스트, 이미지…) |
| `⌘P` | 고정 |
| `⌘⌫` | 삭제 |
| `Esc` | 닫기 |

⌥V나 다른 옵션을 바꾸려면 메뉴 막대의 9clipboard 아이콘을 클릭하고 **설정…**을 선택하십시오.

## 개인정보 보호

- 기록은 사용자의 Mac에만 저장됩니다.
- 9clipboard가 인터넷에 연결하는 유일한 경우는 GitHub에 최신 버전 번호를 확인할 때입니다. 사용자나 클립보드에 관한 정보는 전송되지 않으며, 설정 › 업데이트에서 끌 수 있습니다.
- 손쉬운 사용 권한은 ⌘V를 누르는 데에만 사용됩니다.

## 자주 묻는 질문

**카드를 클릭해도 붙여넣어지지 않습니다.**
설정 › 권한을 확인하십시오. 손쉬운 사용 권한이 없다면 시스템 설정 › 개인정보 보호 및 보안 › 손쉬운 사용에서 9clipboard를 켜십시오.

**어떻게 업데이트하나요?**
설정 › 업데이트에서 업데이트하거나 설치 명령을 다시 실행하십시오. 기록과 설정은 그대로 유지됩니다.

**어떻게 삭제하나요?**
메뉴 막대 아이콘에서 9clipboard를 종료하고 응용 프로그램 폴더에서 휴지통으로 옮기십시오. 기록도 지우려면 `~/Library/Application Support/9clipboard` 폴더를 삭제하십시오.

## 개발자용

소스에서 빌드, 테스트 실행, 릴리스 방법은 [CONTRIBUTING.md](../CONTRIBUTING.md)(영어)를 참고하십시오.

## 라이선스

[MIT](../LICENSE)
