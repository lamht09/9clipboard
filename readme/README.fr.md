# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Un historique du presse-papiers pour votre Mac.** Copiez comme d’habitude, puis appuyez sur **⌥V** (Option‑V) pour retrouver tout ce que vous avez copié — texte, texte mis en forme ou images — et le coller dans l’app que vous utilisez.

Gratuit, open source et privé : votre historique ne quitte jamais votre Mac. Une alternative légère à Paste et Maccy.

![Démo de 9clipboard : ouvrir avec ⌥V, rechercher, filtrer, prévisualiser, cliquer pour coller, glisser une carte vers une autre app, épingler](../assets/demo.gif)

▶ [Voir la démo complète (49 secondes)](../assets/demo.mp4)

## Installation

Il vous faut un Mac avec puce Apple (M1 ou plus récent) sous macOS 14 Sonoma ou version ultérieure.

Ouvrez **Terminal** (appuyez sur ⌘Espace, tapez « Terminal », puis Entrée), collez cette ligne et appuyez sur Entrée :

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

La commande télécharge la dernière version, vérifie qu’il s’agit bien de l’app authentique, la place dans Applications et l’ouvre.

<details>
<summary>Vous préférez la télécharger vous-même ?</summary>

1. Téléchargez `9clipboard-<version>.zip` depuis [Releases](https://github.com/lamht09/9clipboard/releases), décompressez-le et glissez `9clipboard.app` dans Applications.
2. Ouvrez-la. macOS indiquera qu’il ne peut pas vérifier l’app, car 9clipboard n’est pas enregistrée auprès d’Apple. Allez dans **Réglages Système › Confidentialité et sécurité** et cliquez sur **Ouvrir quand même**. Il faut le faire une fois pour chaque nouvelle version téléchargée ainsi.

</details>

## Premiers pas

1. Copiez quelques éléments comme d’habitude.
2. Appuyez sur **⌥V**. Votre historique apparaît sous forme de cartes en bas de l’écran.
3. Cliquez sur une carte (ou appuyez sur Entrée) : elle est collée dans l’app que vous utilisiez.

La première fois, macOS vous demande d’autoriser l’**Accessibilité** pour 9clipboard. Cela lui permet d’appuyer sur ⌘V à votre place. Activez-la dans **Réglages Système › Confidentialité et sécurité › Accessibilité**. Si vous préférez ne pas le faire, 9clipboard fonctionne quand même : un clic sur une carte la copie et vous appuyez vous-même sur ⌘V, ou vous glissez la carte dans l’autre app.

## Ce qu’elle fait

- **Retrouve tout rapidement.** Commencez à taper. Pas besoin d’accents ni de mots complets : `creme brulee` trouve « Crème brûlée ».
- **Trouve le chinois, le japonais et le coréen à l’oreille.** Tapez le pinyin, le romaji ou les consonnes initiales : `beijing` trouve « 北京 », `tokyo` trouve « 東京タワー », `ㅎㄱ` trouve « 한국 ».
- **Colle sans mise en forme** avec ⇧Entrée.
- **Glisser-déposer.** Glissez une carte dans un document, une conversation, Notes ou le Finder.
- **Garde ce que vous réutilisez.** Épinglez des cartes dans des Pinboards ; les cartes épinglées ne sont jamais supprimées.
- **Fait le ménage dans les mots de passe.** Les mots de passe copiés depuis 1Password, Mots de passe et apps similaires sont supprimés au bout de 15 minutes, sauf si vous les conservez.
- **Reste discrète.** Excluez les apps que vous ne voulez pas enregistrer, ou suspendez l’enregistrement depuis la barre des menus.
- **Parle votre langue.** English, Tiếng Việt, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch, Português, Русский, Italiano.
- **Se met à jour toute seule** depuis Réglages › Mises à jour.

## Raccourcis clavier

Dans le panneau :

| Touche | Action |
|---|---|
| Taper | Rechercher |
| `←` `→` | Passer d’une carte à l’autre |
| `Entrée` ou clic | Coller |
| `⇧Entrée` | Coller en texte brut |
| `⌘1` … `⌘9` | Coller la carte 1 à 9 |
| `Espace` | Grand aperçu |
| `Tab` | Filtre suivant (Tout, Texte, Image…) |
| `⌘P` | Épingler |
| `⌘⌫` | Supprimer |
| `Échap` | Fermer |

Pour changer ⌥V et d’autres options, cliquez sur l’icône de 9clipboard dans la barre des menus et choisissez **Réglages…**.

## Confidentialité

- Votre historique est stocké uniquement sur votre Mac.
- 9clipboard ne se connecte à Internet que pour demander à GitHub le dernier numéro de version. Rien sur vous ni sur votre presse-papiers n’est envoyé, et vous pouvez le désactiver dans Réglages › Mises à jour.
- L’accès Accessibilité sert uniquement à appuyer sur ⌘V à votre place.

## Questions

**Cliquer sur une carte ne colle rien.**
Vérifiez Réglages › Autorisations. Si l’Accessibilité n’est pas autorisée, activez 9clipboard dans Réglages Système › Confidentialité et sécurité › Accessibilité.

**Comment la mettre à jour ?**
Depuis Réglages › Mises à jour, ou en relançant la commande d’installation. Votre historique et vos réglages sont conservés.

**Comment la désinstaller ?**
Quittez 9clipboard depuis son icône dans la barre des menus et placez l’app d’Applications dans la Corbeille. Pour effacer aussi l’historique, supprimez le dossier `~/Library/Application Support/9clipboard`.

## Pour les développeurs

Compiler depuis les sources, lancer les tests et publier : voir [CONTRIBUTING.md](../CONTRIBUTING.md) (en anglais).

## Licence

[MIT](../LICENSE)
