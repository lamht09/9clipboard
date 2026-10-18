# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · **Italiano**

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Una cronologia degli appunti per il tuo Mac.** Copia come sempre, poi premi **⌥V** (Opzione‑V) per recuperare qualsiasi cosa tu abbia copiato prima — testo, testo formattato o immagini — e incollarla nell’app che stai usando.

Gratuita, open source e privata: la cronologia non lascia mai il tuo Mac. Un’alternativa leggera a Paste e Maccy.

![Demo di 9clipboard: apri con ⌥V, cerca, filtra, anteprima, fai clic per incollare, trascina una scheda in un’altra app, fissa](../assets/demo.gif)

▶ [Guarda la demo completa (49 secondi)](../assets/demo.mp4)

## Installazione

Ti serve un Mac con Apple Silicon (M1 o successivo) e macOS 14 Sonoma o versioni successive.

Apri **Terminale** (premi ⌘Spazio, digita “Terminale” e premi Invio), incolla questa riga e premi Invio:

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

Il comando scarica l’ultima versione, verifica che sia l’app originale, la mette in Applicazioni e la apre.

<details>
<summary>Preferisci scaricarla tu?</summary>

1. Scarica `9clipboard-<versione>.zip` da [Releases](https://github.com/lamht09/9clipboard/releases), decomprimilo e trascina `9clipboard.app` in Applicazioni.
2. Aprila. macOS dirà che non può verificare l’app, perché 9clipboard non è registrata presso Apple. Vai in **Impostazioni di Sistema › Privacy e sicurezza** e fai clic su **Apri comunque**. Serve una volta per ogni nuova versione scaricata in questo modo.

</details>

## Per iniziare

1. Copia qualcosa come fai di solito.
2. Premi **⌥V**. La cronologia appare come una fila di schede in fondo allo schermo.
3. Fai clic su una scheda (o premi Invio) e viene incollata nell’app che stavi usando.

La prima volta, macOS ti chiede di consentire **Accessibilità** a 9clipboard. Così può premere ⌘V al posto tuo. Attivala in **Impostazioni di Sistema › Privacy e sicurezza › Accessibilità**. Se preferisci di no, 9clipboard funziona lo stesso: un clic su una scheda la copia e premi tu ⌘V, oppure trascini la scheda nell’altra app.

## Cosa fa

- **Trova tutto in fretta.** Inizia a digitare. Non servono accenti né parole intere: `perche` trova “Perché”.
- **Incolla senza formattazione** con ⇧Invio.
- **Trascina e rilascia.** Trascina una scheda in un documento, una chat, Note o il Finder.
- **Conserva ciò che riusi.** Fissa le schede nei Pinboard; le schede fissate non vengono mai eliminate.
- **Fa pulizia delle password.** Le password copiate da 1Password, Password e app simili vengono eliminate dopo 15 minuti, a meno che tu non le mantenga.
- **Non disturba.** Escludi le app che non vuoi registrare o metti in pausa la registrazione dalla barra dei menu.
- **Parla la tua lingua.** English, Tiếng Việt, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch, Português, Русский, Italiano.
- **Si aggiorna da sola** da Impostazioni › Aggiornamenti.

## Abbreviazioni da tastiera

Nel pannello:

| Tasto | Azione |
|---|---|
| Digita | Cerca |
| `←` `→` | Spostati tra le schede |
| `Invio` o clic | Incolla |
| `⇧Invio` | Incolla come testo semplice |
| `⌘1` … `⌘9` | Incolla la scheda 1–9 |
| `Spazio` | Anteprima grande |
| `Tab` | Filtro successivo (Tutto, Testo, Immagine…) |
| `⌘P` | Fissa |
| `⌘⌫` | Elimina |
| `Esc` | Chiudi |

Per cambiare ⌥V e altre opzioni, fai clic sull’icona di 9clipboard nella barra dei menu e scegli **Impostazioni…**.

## Privacy

- La cronologia viene salvata solo sul tuo Mac.
- 9clipboard si collega a Internet solo per chiedere a GitHub il numero dell’ultima versione. Non viene inviato nulla su di te o sui tuoi appunti, e puoi disattivarlo in Impostazioni › Aggiornamenti.
- L’accesso ad Accessibilità serve solo a premere ⌘V al posto tuo.

## Domande

**Facendo clic su una scheda non viene incollato nulla.**
Controlla Impostazioni › Autorizzazioni. Se Accessibilità non è consentita, attiva 9clipboard in Impostazioni di Sistema › Privacy e sicurezza › Accessibilità.

**Come la aggiorno?**
Da Impostazioni › Aggiornamenti, oppure eseguendo di nuovo il comando di installazione. Cronologia e impostazioni vengono mantenute.

**Come la disinstallo?**
Esci da 9clipboard dalla sua icona nella barra dei menu e sposta l’app da Applicazioni al Cestino. Per eliminare anche la cronologia, elimina la cartella `~/Library/Application Support/9clipboard`.

## Per sviluppatori

Compilare dal codice sorgente, eseguire i test e pubblicare le versioni: vedi [CONTRIBUTING.md](../CONTRIBUTING.md) (in inglese).

## Licenza

[MIT](../LICENSE)
