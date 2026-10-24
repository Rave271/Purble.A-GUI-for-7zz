<p align="center">
  <img src="assets/banner.svg" alt="Purble" width="100%">
</p>

<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-9C3AFF?style=flat-square&labelColor=000000">
  <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple%20Silicon-arm64-9C3AFF?style=flat-square&labelColor=000000">
  <img alt="SwiftUI" src="https://img.shields.io/badge/built%20with-SwiftUI-9C3AFF?style=flat-square&labelColor=000000">
  <img alt="Engine: 7-Zip" src="https://img.shields.io/badge/engine-7--Zip-9C3AFF?style=flat-square&labelColor=000000">
</p>

---

## 01 — WHAT IT DOES

Purble is a small macOS app for extracting archives without typing commands. Drag an archive in, pick where it goes, hit Extract. Under the hood it drives the official 7-Zip command-line tool (`7zz`), which ships inside the app, so there is nothing else to install.

```
┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐
╎                                        ╎
╎          drop an archive here          ╎
╎           or click to choose           ╎
╎                                        ╎
└╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘

  [██████████████░░░░░░░░░░░░]  58%
  EXTRACTING…
```

- Drag and drop, or click to pick a file
- Live progress bar, with a cancel button
- Password-protected archives: the password box appears only when one is needed
- Split archives: open any part (`.7z.001`, `.002`, …) and Purble finds the first part and checks for gaps before starting
- Output goes to a folder next to the archive, named after it (change it any time)
- Settings (`⌘,`): point Purble at your own `7zz`, such as Homebrew's, instead of the built-in one

## 02 — INSTALL

1. Download `Purble.zip` from the [Releases](../../releases) page and unzip it.
2. Move `Purble.app` to Applications.
3. First launch: **System Settings → Privacy & Security → Open Anyway**. The app isn't notarized, so macOS asks once.

Requires macOS 13 or newer on Apple Silicon.

## 03 — BUILD FROM SOURCE

You need the Swift toolchain. The Command Line Tools are enough, Xcode isn't required. Put the official `7zz` binary and its `License.txt` in `bin/`, then:

```
swift run            # run in dev mode
./build-app.sh       # build dist/Purble.app and dist/Purble.zip
```

Optional: drop an `AppIcon.icns` in the project root and the build script bundles it.

## 04 — HOW IT WORKS

```
window (SwiftUI)  ──▶  SevenZipEngine  ──▶  7zz (bundled)
       ▲                     │
       └── progress / result ┘
```

The window never touches command-line flags. The engine runs `7zz` through `Process`, reads its output as it streams in, and hands the window simple events: a percentage, or a result (success, wrong password, failed).

| File | Job |
| --- | --- |
| `App.swift` | The window and its states |
| `SevenZipEngine.swift` | Runs 7zz, streams progress, maps errors |
| `SevenZipLocator.swift` | Finds 7zz: Settings override → bundled copy → dev copy → Homebrew |
| `Volumes.swift` | Split-archive detection |
| `SettingsView.swift` | The `⌘,` window |
| `Wireframe.swift` | The look: palette, dotted frames, buttons |
| `build-app.sh` | Builds and packages `Purble.app` |

## 05 — KNOWN LIMITS

- Extract only. No compression yet.
- Apple Silicon only.
- Not notarized, so the first launch needs "Open Anyway".
- Mostly tested with `.7z` archives.
- Multi-part RAR naming (`.part1.rar`) is untested, and split zips (`.z01`, `.z02`) aren't handled.
- If the *last* part of a split set is missing, it can only be caught by 7zz partway through the run.

## 06 — BUILT WITH CLAUDE

I built Purble in a pair-programming chat with **Claude Sonnet 5.5**, an AI assistant made by [Anthropic](https://www.anthropic.com).

| Who | What |
| --- | --- |
| Me | The idea, the product decisions (bundle 7zz, the purple-on-black wireframe look, dotted lines, no handles), running every step, testing, bug reports |
| Claude Sonnet 5.5 | Explained the approach and wrote the Swift code, the build script and this README, one small step at a time |

Each step was run on a real Mac before moving on. Claude got a few things wrong along the way, like a wrong project template and a path that didn't expand. Running the code is what caught them.

## 07 — LICENSE & CREDITS

Purble is released under the MIT license. See `LICENSE`.

Purble bundles the unmodified 7-Zip command-line binary (`7zz`) by Igor Pavlov, from https://www.7-zip.org, licensed under the GNU LGPL with an unRAR restriction. The license text is in `bin/License.txt` and inside the app bundle.

---

<p align="center"><sub>extract. no terminal.</sub></p>