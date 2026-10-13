# Silence SpeedUp

![Logo](assets/icons/icon.png)

**Silence SpeedUp** shortens videos by finding the silent stretches and either
speeding them up or cutting them out. FFmpeg does the encoding; this app decides
what to ask it for.

Made for lectures, interviews, podcasts and tutorials — anything where the
speaker pauses a lot or talks slowly.

**On Windows, get it from the
[Microsoft Store](https://apps.microsoft.com/detail/9NJ11SB1S9P5).** The
Store keeps it up to date, and the package is signed, so there are no
warnings about an unknown publisher.

Version 3 is a **rewrite in Flutter**. Versions 1.x and 2.x were an Electron
app; their source is on the [`electron`](https://github.com/padvincenzo/silence-speedup/tree/electron)
branch and their builds stay on the
[releases page](https://github.com/padvincenzo/silence-speedup/releases).

---

## Why Flutter

**FFmpeg is bundled.** There is no path to configure, no binary to download and
no preference to get wrong; installing the app is the whole setup. The plugin
that provides it
([`ffmpeg_kit_flutter_new`](https://pub.dev/packages/ffmpeg_kit_flutter_new),
full-GPL, includes `libx264`) covers Android, iOS, macOS and Linux behind the
same API, so the same processing pipeline can follow the app to a phone later.
See [ROADMAP.md](ROADMAP.md).

The rest follows from that choice. The app is native rather than a browser in a
window, the interface is Material and built for the job, and the part that
decides what to ask FFmpeg for is pure: every argument list the app runs is
built in one place and asserted in a test, because a wrong flag there produces a
file that is subtly out of sync rather than an error.

[docs/porting-notes.md](docs/porting-notes.md) records where this version
behaves differently from the Electron app, for anyone moving between the two.

---

## Status

The processing pipeline and the desktop UI are complete and the Windows build
works. The demo player from the Electron version is not ported yet — see
[ROADMAP.md](ROADMAP.md).

Coming from 2.x: this is a new installation, not an update in place. Settings
are not carried over, and the FFmpeg path is gone because FFmpeg is now
bundled. If you are on macOS and need a build today, the 2.x releases still
work.

Primary target is **Windows**. **Linux** builds and is tested, see
[docs/linux.md](docs/linux.md), and how it will be distributed is not decided
yet. macOS should build from source but is not tested. Android is scaffolded
but has no UI.

---

## Getting started

1. Launch the app.
2. Add your videos — **Add video(s)**, a folder, or drag them onto the window.
3. Adjust the settings if you want to (the defaults are sensible).
4. Press the play button on a row to hear a **short preview sample** first, then
   press **Start**.

Results land next to the original videos by default; the export folder sits on
the main window, not behind a menu.

Full walkthrough of every setting: [docs/usage.md](docs/usage.md).

---

## Features

- 🎙️ **Silence detection you can tune** — noise floor, minimum pause length,
  and a margin so words are not clipped
- ⏩ **Speed up or remove** the silences, and optionally mute them
- 🗣️ **Speed up the speech too**, if you want the whole thing faster
- 🎧 **Multi-track audio** — carry every audio track through while detecting the
  pauses from the first one, which is what an OBS capture with voice on track 1
  and system audio on track 2 needs
- ▶️ **Preview before you commit** — encode a short sample through the real
  pipeline and hear the result, without waiting for the whole file
- 🔍 **Or just measure** — a detection-only pass reports how much of a file is
  silence in seconds rather than minutes
- 📁 **The export folder is where you need it** — on the main window, editable
  in place, defaulting to the source video's own folder
- 📋 **Batch processing** with a queue, a live log and an interruptible run
- 🎛️ **Encoder controls** — CRF, frame rate, x264 preset and tune, audio rate,
  output container
- 🪟 **Compact progress mode** — a slim always-on-top strip for long batches
- 🧭 **Material interface** — a navigation drawer, encoding settings that
  dock beside the queue on a wide window, and an app settings page that
  explains each option in place, rather than a menu bar and a modal
- 🌗 **Light, dark or system theme**
- 🌍 **English and Italian**, following the system language by default
- 📦 **FFmpeg included** — nothing to install

---

## Requirements

Nothing, for a packaged build: FFmpeg ships with the app. Windows 10 or newer,
64-bit.

### Building from source

Flutter 3.47+ and, on Windows, Visual Studio 2022 with the C++ desktop
workload — see [docs/development.md](docs/development.md).

```bash
git clone https://github.com/padvincenzo/silence-speedup
cd silence-speedup
flutter pub get
flutter run -d windows
```

### Packaging for the Microsoft Store

```powershell
.\installer\build-msix.ps1
```

The result is `dist\SilenceSpeedUp-<version>-store.msix`, for uploading in
Partner Center. It is unsigned on purpose, because the Store signs it; see
[docs/microsoft-store.md](docs/microsoft-store.md).

### Packaging the installer

Additionally [Inno Setup 6](https://jrsoftware.org/isinfo.php):

```powershell
winget install --id JRSoftware.InnoSetup --source winget
.\installer\build-installer.ps1
```

The result is `dist\SilenceSpeedUp-<version>-windows-x64-setup.exe`.

---

## Documentation

| Document | What is in it |
| --- | --- |
| [docs/usage.md](docs/usage.md) | Every setting, what it does, and how to fix a bad result |
| [docs/architecture.md](docs/architecture.md) | How the code is organised and why |
| [docs/ffmpeg-details.md](docs/ffmpeg-details.md) | The exact FFmpeg commands, flag by flag |
| [docs/porting-notes.md](docs/porting-notes.md) | What changed from the Electron app, and why |
| [docs/development.md](docs/development.md) | Building, testing, releasing, extending |
| [docs/linux.md](docs/linux.md) | Building and trying the Linux version, from Windows too |
| [ROADMAP.md](ROADMAP.md) | What is not built yet |
| [CLAUDE.md](CLAUDE.md) | Working rules for AI assistants in this repo |

---

## Contributing

Welcome, in any of these forms:

- Reporting bugs
- Translating the app (copy `lib/l10n/arb/app_en.arb`, change `@@locale`, and
  run `flutter gen-l10n`; the new language appears in the menu on its own)
- Suggesting or implementing features from [ROADMAP.md](ROADMAP.md)
- [Buying me a coffee](https://paypal.me/VincenzoPadula)

Before a pull request: `flutter analyze` clean, `flutter test` green, and any
change to the FFmpeg calls covered by a test in
[test/fragment_planner_test.dart](test/fragment_planner_test.dart) or
[test/preview_and_audio_test.dart](test/preview_and_audio_test.dart).

---

## Credits

- [FFmpeg](https://ffmpeg.org/), bundled under the **GPLv3**, via
  [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new)
- [Flutter](https://flutter.dev/) for the interface
- Icons from [creazilla.com](https://creazilla.com/) under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

## AI assistance

Parts of the code were written with an AI assistant, then reviewed and
maintained by the author, who is responsible for it.

The app itself contains **no AI**, and sends nothing anywhere: the silences are
found by measuring the audio level with FFmpeg's `silencedetect`, which is a
threshold and a stopwatch, not a model.

## Licence

GPLv3 or later. Copyright (C) 2026 Vincenzo Padula.

This program comes with **absolutely no warranty**. It is free software, and you
are welcome to redistribute it under certain conditions; see [LICENSE](LICENSE).
