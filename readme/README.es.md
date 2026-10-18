# 9clipboard

[English](../README.md) · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Español** · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [Italiano](README.it.md)

[![Release](https://img.shields.io/github/v/release/lamht09/9clipboard?include_prereleases&sort=semver)](https://github.com/lamht09/9clipboard/releases) [![Downloads](https://img.shields.io/github/downloads/lamht09/9clipboard/total)](https://github.com/lamht09/9clipboard/releases) ![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

**Un historial del portapapeles para tu Mac.** Copia como siempre y pulsa **⌥V** (Opción‑V) para recuperar cualquier cosa que hayas copiado antes —texto, texto con formato o imágenes— y pegarla en la app que estés usando.

Gratis, de código abierto y privado: tu historial nunca sale de tu Mac. Una alternativa ligera a Paste y Maccy.

![Demo de 9clipboard: abrir con ⌥V, buscar, filtrar, previsualizar, hacer clic para pegar, arrastrar una tarjeta a otra app, fijar](../assets/demo.gif)

▶ [Ver la demo completa (49 segundos)](../assets/demo.mp4)

## Instalación

Necesitas un Mac con Apple Silicon (M1 o posterior) y macOS 14 Sonoma o posterior.

Abre **Terminal** (pulsa ⌘Espacio, escribe “Terminal” y pulsa Intro), pega esta línea y pulsa Intro:

```sh
curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
```

Descarga la última versión, comprueba que es la app auténtica, la coloca en Aplicaciones y la abre.

<details>
<summary>¿Prefieres descargarla tú?</summary>

1. Descarga `9clipboard-<versión>.zip` desde [Releases](https://github.com/lamht09/9clipboard/releases), descomprímelo y arrastra `9clipboard.app` a Aplicaciones.
2. Ábrela. macOS dirá que no puede comprobar la app, porque 9clipboard no está registrada en Apple. Ve a **Ajustes del Sistema › Privacidad y seguridad** y haz clic en **Abrir igualmente**. Tendrás que hacerlo una vez por cada versión nueva que descargues así.

</details>

## Primeros pasos

1. Copia algunas cosas como siempre.
2. Pulsa **⌥V**. Tu historial aparece como una fila de tarjetas en la parte inferior de la pantalla.
3. Haz clic en una tarjeta (o pulsa Intro) y se pegará en la app que estabas usando.

La primera vez, macOS te pedirá que permitas **Accesibilidad** a 9clipboard. Así puede pulsar ⌘V por ti. Actívalo en **Ajustes del Sistema › Privacidad y seguridad › Accesibilidad**. Si prefieres no hacerlo, 9clipboard sigue funcionando: al hacer clic en una tarjeta se copia y tú pulsas ⌘V, o arrastras la tarjeta a la otra app.

## Qué hace

- **Encuentra todo rápido.** Empieza a escribir. No hacen falta tildes ni palabras completas: `cancion` encuentra “Canción”.
- **Encuentra chino, japonés y coreano por cómo suena.** Escribe pinyin, romaji o consonantes iniciales: `beijing` encuentra “北京”, `tokyo` encuentra “東京タワー”, `ㅎㄱ` encuentra “한국”.
- **Pega sin formato** al pulsar ⇧Intro.
- **Arrastrar y soltar.** Arrastra una tarjeta a un documento, un chat, Notas o Finder.
- **Guarda lo que reutilizas.** Fija tarjetas en Pinboards; las tarjetas fijadas nunca se eliminan.
- **Limpia las contraseñas.** Las contraseñas copiadas desde 1Password, Contraseñas y apps similares se eliminan a los 15 minutos, salvo que las conserves.
- **No molesta.** Excluye las apps que no quieras registrar o pausa el registro desde la barra de menús.
- **Habla tu idioma.** English, Tiếng Việt, 简体中文, 繁體中文, 日本語, 한국어, Español, Français, Deutsch, Português, Русский, Italiano.
- **Se actualiza sola** desde Ajustes › Actualizaciones.

## Atajos de teclado

En el panel:

| Tecla | Acción |
|---|---|
| Escribir | Buscar |
| `←` `→` | Moverse entre tarjetas |
| `Intro` o clic | Pegar |
| `⇧Intro` | Pegar como texto sin formato |
| `⌘1` … `⌘9` | Pegar la tarjeta 1–9 |
| `Espacio` | Vista previa grande |
| `Tab` | Siguiente filtro (Todo, Texto, Imagen…) |
| `⌘P` | Fijar |
| `⌘⌫` | Eliminar |
| `Esc` | Cerrar |

Para cambiar ⌥V y otras opciones, haz clic en el icono de 9clipboard en la barra de menús y elige **Ajustes…**.

## Privacidad

- Tu historial se guarda solo en tu Mac.
- 9clipboard solo se conecta a internet para preguntar a GitHub el número de la última versión. No se envía nada sobre ti ni sobre tu portapapeles, y puedes desactivarlo en Ajustes › Actualizaciones.
- El acceso de Accesibilidad solo se usa para pulsar ⌘V por ti.

## Preguntas

**Al hacer clic en una tarjeta no se pega.**
Revisa Ajustes › Permisos. Si Accesibilidad no está permitida, activa 9clipboard en Ajustes del Sistema › Privacidad y seguridad › Accesibilidad.

**¿Cómo la actualizo?**
Desde Ajustes › Actualizaciones, o ejecuta de nuevo el comando de instalación. Tu historial y tus ajustes se conservan.

**¿Cómo la desinstalo?**
Sal de 9clipboard desde su icono en la barra de menús y mueve la app de Aplicaciones a la Papelera. Para borrar también el historial, elimina la carpeta `~/Library/Application Support/9clipboard`.

## Para desarrolladores

Compilar desde el código fuente, ejecutar pruebas y publicar versiones: consulta [CONTRIBUTING.md](../CONTRIBUTING.md) (en inglés).

## Licencia

[MIT](../LICENSE)
