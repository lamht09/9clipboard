# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · **Deutsch** · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Ein Zwischenablageverlauf für deinen Mac.** Kopiere wie gewohnt und drücke dann **⌥V** (Wahl‑V), um alles zurückzuholen, was du vorher kopiert hast – Text, formatierten Text oder Bilder – und es in die App einzusetzen, die du gerade benutzt.

Kostenlos, Open Source und privat: Dein Verlauf verlässt nie deinen Mac. Eine schlanke Alternative zu Paste und Maccy.

![9clipboard-Demo: mit ⌥V öffnen, suchen, filtern, Vorschau, zum Einsetzen klicken, Karte in eine andere App ziehen, anheften](../assets/demo.gif)

▶ [Ganze Demo ansehen (49 Sekunden)](../assets/demo.mp4)

## Installation

Du brauchst einen Mac mit Apple Chip (M1 oder neuer) und macOS 14 Sonoma oder neuer.

Öffne das **Terminal** (⌘Leertaste drücken, „Terminal“ eingeben, Eingabetaste), füge diese Zeile ein und drücke die Eingabetaste:

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

Der Befehl lädt die neueste Version, prüft, dass es die echte App ist, legt sie in „Programme“ und öffnet sie.

<details>
<summary>Lieber selbst herunterladen?</summary>

1. Lade `9clipboard-<Version>.zip` von [Releases](https://github.com/lamht09/9clipboard/releases), entpacke es und ziehe `9clipboard.app` in „Programme“.
2. Öffne die App. macOS meldet, dass die App nicht überprüft werden kann, weil 9clipboard nicht bei Apple registriert ist. Gehe zu **Systemeinstellungen › Datenschutz & Sicherheit** und klicke auf **Dennoch öffnen**. Das ist für jede so geladene neue Version einmal nötig.

</details>

## Erste Schritte

1. Kopiere wie gewohnt ein paar Dinge.
2. Drücke **⌥V**. Dein Verlauf erscheint als Kartenreihe am unteren Bildschirmrand.
3. Klicke auf eine Karte (oder drücke die Eingabetaste) – sie wird in die App eingesetzt, die du gerade benutzt hast.

Beim ersten Mal bittet macOS dich, 9clipboard Zugriff auf die **Bedienungshilfen** zu erlauben. Damit kann es ⌘V für dich drücken. Aktiviere es unter **Systemeinstellungen › Datenschutz & Sicherheit › Bedienungshilfen**. Wenn du das nicht möchtest, funktioniert 9clipboard trotzdem: Ein Klick auf eine Karte kopiert sie und du drückst selbst ⌘V, oder du ziehst die Karte in die andere App.

## Was es kann

- **Findet alles schnell.** Einfach lostippen. Akzente oder ganze Wörter sind nicht nötig: `munchen` findet „München“.
- **Ohne Formatierung einsetzen** mit ⇧Eingabe.
- **Drag & Drop.** Ziehe eine Karte in ein Dokument, einen Chat, Notizen oder den Finder.
- **Behält, was du oft brauchst.** Hefte Karten an Pinboards an; angeheftete Karten werden nie gelöscht.
- **Räumt Passwörter auf.** Aus 1Password, Passwörter und ähnlichen Apps kopierte Passwörter werden nach 15 Minuten gelöscht, außer du behältst sie.
- **Stört nicht.** Schließe Apps aus, die nicht aufgezeichnet werden sollen, oder pausiere die Aufzeichnung über die Menüleiste.
- **Spricht deine Sprache.** English, Tiếng Việt, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch, Português, Русский, Italiano.
- **Aktualisiert sich selbst** unter Einstellungen › Updates.

## Tastenkürzel

Im Panel:

| Taste | Aktion |
|---|---|
| Tippen | Suchen |
| `←` `→` | Zwischen Karten wechseln |
| `Eingabe` oder Klick | Einsetzen |
| `⇧Eingabe` | Als reinen Text einsetzen |
| `⌘1` … `⌘9` | Karte 1–9 einsetzen |
| `Leertaste` | Große Vorschau |
| `Tab` | Nächster Filter (Alle, Text, Bild …) |
| `⌘P` | Anheften |
| `⌘⌫` | Löschen |
| `Esc` | Schließen |

Um ⌥V und andere Optionen zu ändern, klicke auf das 9clipboard-Symbol in der Menüleiste und wähle **Einstellungen …**.

## Datenschutz

- Dein Verlauf wird nur auf deinem Mac gespeichert.
- 9clipboard geht nur online, um bei GitHub die neueste Versionsnummer abzufragen. Dabei wird nichts über dich oder deine Zwischenablage gesendet, und du kannst es unter Einstellungen › Updates ausschalten.
- Der Zugriff auf die Bedienungshilfen wird nur genutzt, um ⌘V für dich zu drücken.

## Fragen

**Ein Klick auf eine Karte setzt nichts ein.**
Sieh unter Einstellungen › Berechtigungen nach. Ist der Zugriff auf die Bedienungshilfen nicht erlaubt, aktiviere 9clipboard unter Systemeinstellungen › Datenschutz & Sicherheit › Bedienungshilfen.

**Wie aktualisiere ich?**
Unter Einstellungen › Updates oder indem du den Installationsbefehl erneut ausführst. Verlauf und Einstellungen bleiben erhalten.

**Wie deinstalliere ich?**
Beende 9clipboard über das Symbol in der Menüleiste und bewege die App aus „Programme“ in den Papierkorb. Um auch den Verlauf zu löschen, lösche den Ordner `~/Library/Application Support/9clipboard`.

## Für Entwickler

Aus dem Quellcode bauen, Tests ausführen und Releases erstellen: siehe [CONTRIBUTING.md](../CONTRIBUTING.md) (auf Englisch).

## Lizenz

[MIT](../LICENSE)
