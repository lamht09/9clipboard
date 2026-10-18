# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · **Português** · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Um histórico da área de transferência para o seu Mac.** Copie como sempre e pressione **⌥V** (Option‑V) para recuperar qualquer coisa que você copiou antes — texto, texto formatado ou imagens — e colar no app que está usando.

Gratuito, de código aberto e privado: seu histórico nunca sai do seu Mac. Uma alternativa leve ao Paste e ao Maccy.

![Demonstração do 9clipboard: abrir com ⌥V, buscar, filtrar, pré-visualizar, clicar para colar, arrastar um cartão para outro app, fixar](../assets/demo.gif)

▶ [Assista à demonstração completa (49 segundos)](../assets/demo.mp4)

## Instalação

Você precisa de um Mac com Apple Silicon (M1 ou mais recente) e macOS 14 Sonoma ou posterior.

Abra o **Terminal** (pressione ⌘Espaço, digite “Terminal” e pressione Return), cole esta linha e pressione Return:

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

O comando baixa a versão mais recente, confere se é o app original, coloca-o em Aplicativos e o abre.

<details>
<summary>Prefere baixar você mesmo?</summary>

1. Baixe `9clipboard-<versão>.zip` em [Releases](https://github.com/lamht09/9clipboard/releases), descompacte e arraste `9clipboard.app` para Aplicativos.
2. Abra o app. O macOS dirá que não consegue verificar o app, porque o 9clipboard não é registrado na Apple. Vá em **Ajustes do Sistema › Privacidade e Segurança** e clique em **Abrir Mesmo Assim**. Isso é necessário uma vez para cada nova versão baixada dessa forma.

</details>

## Primeiros passos

1. Copie algumas coisas como sempre.
2. Pressione **⌥V**. Seu histórico aparece como uma fileira de cartões na parte de baixo da tela.
3. Clique em um cartão (ou pressione Return) e ele é colado no app que você estava usando.

Na primeira vez, o macOS pede que você permita **Acessibilidade** para o 9clipboard. Isso permite que ele pressione ⌘V por você. Ative em **Ajustes do Sistema › Privacidade e Segurança › Acessibilidade**. Se preferir não ativar, o 9clipboard continua funcionando: clicar em um cartão o copia e você pressiona ⌘V, ou arrasta o cartão para o outro app.

## O que ele faz

- **Encontra tudo rápido.** É só começar a digitar. Não precisa de acentos nem de palavras completas: `sao paulo` encontra “São Paulo”.
- **Cola sem formatação** com ⇧Return.
- **Arrastar e soltar.** Arraste um cartão para um documento, uma conversa, o Notas ou o Finder.
- **Guarda o que você reutiliza.** Fixe cartões em Pinboards; cartões fixados nunca são apagados.
- **Limpa senhas.** Senhas copiadas do 1Password, Senhas e apps parecidos são apagadas após 15 minutos, a menos que você as mantenha.
- **Não atrapalha.** Exclua apps que você não quer registrar ou pause o registro pela barra de menus.
- **Fala o seu idioma.** English, Tiếng Việt, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch, Português, Русский, Italiano.
- **Atualiza sozinho** em Ajustes › Atualizações.

## Atalhos de teclado

No painel:

| Tecla | Ação |
|---|---|
| Digitar | Buscar |
| `←` `→` | Mover entre cartões |
| `Return` ou clique | Colar |
| `⇧Return` | Colar como texto simples |
| `⌘1` … `⌘9` | Colar o cartão 1–9 |
| `Espaço` | Pré-visualização grande |
| `Tab` | Próximo filtro (Tudo, Texto, Imagem…) |
| `⌘P` | Fixar |
| `⌘⌫` | Apagar |
| `Esc` | Fechar |

Para mudar o ⌥V e outras opções, clique no ícone do 9clipboard na barra de menus e escolha **Ajustes…**.

## Privacidade

- Seu histórico fica salvo apenas no seu Mac.
- O 9clipboard só se conecta à internet para perguntar ao GitHub o número da versão mais recente. Nada sobre você ou sua área de transferência é enviado, e você pode desativar isso em Ajustes › Atualizações.
- O acesso à Acessibilidade é usado apenas para pressionar ⌘V por você.

## Perguntas

**Clicar em um cartão não cola nada.**
Confira Ajustes › Permissões. Se a Acessibilidade não estiver permitida, ative o 9clipboard em Ajustes do Sistema › Privacidade e Segurança › Acessibilidade.

**Como atualizo?**
Em Ajustes › Atualizações, ou executando o comando de instalação de novo. Seu histórico e seus ajustes são mantidos.

**Como desinstalo?**
Encerre o 9clipboard pelo ícone na barra de menus e mova o app de Aplicativos para o Lixo. Para apagar também o histórico, apague a pasta `~/Library/Application Support/9clipboard`.

## Para desenvolvedores

Compilar a partir do código-fonte, rodar testes e publicar versões: veja [CONTRIBUTING.md](../CONTRIBUTING.md) (em inglês).

## Licença

[MIT](../LICENSE)
