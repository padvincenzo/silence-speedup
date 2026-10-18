# Silence SpeedUp

![Logo](assets/icons/icon.png)

**Silence SpeedUp** shortens videos by finding the silent stretches and either
speeding them up or cutting them out. FFmpeg does the encoding; this app decides
what to ask it for.

Made for lectures, interviews, podcasts and tutorials — anything where the
speaker pauses a lot or talks slowly.

## Download

<a href="https://apps.microsoft.com/detail/9NJ11SB1S9P5?mode=direct"><img src="https://get.microsoft.com/images/en-us%20dark.svg" alt="Get it from Microsoft" width="200"></a>

- **Free, for Windows and Linux:** from the
  [latest release](https://github.com/padvincenzo/silence-speedup/releases/latest).
  The Windows installer is not signed, so Windows SmartScreen may warn about
  an unknown publisher the first time; choose *More info → Run anyway*.
- **From the [Microsoft Store](https://apps.microsoft.com/detail/9NJ11SB1S9P5):**
  the same app, signed and kept up to date by the Store. It is paid, and
  buying it is also a way to support the project.
- **From source:** see [Building from source](#building-from-source).

Coming from 2.x? See [docs/porting-notes.md](docs/porting-notes.md#coming-from-2x).
A presentation of the app, in English and Italian, is on
[the author's site](https://www.vincenzopadula.it/en/silence-speedup-en/).

## Getting started

1. Add your videos — **Add**, a folder, or drag them onto the window.
2. Adjust the settings if you want to; the defaults suit most recordings.
3. Press the play button on a row to hear a **short preview sample** first,
   then press **Start**.

Results land next to the original videos by default; another folder can be
chosen in the **Export** group of the encoding settings.

Full walkthrough of every setting: [docs/usage.md](docs/usage.md).

## Features

- ⏩ **Speed up or remove** the silences, and optionally mute them
- 🗣️ **Speed up the speech too**, if you want the whole video faster
- 🎙️ **Tunable detection** — noise threshold, minimum pause length, and a margin
  so words are not clipped
- 📏 **A measured threshold** — the app reads the recording's background noise
  and voice level and suggests the value between them
- ▶️ **Preview** — encode a short sample and hear the result before processing
  the whole file
- 🔍 **Quick analysis** — every pause on a zoomable timeline, with the estimated
  length of the result
- 🎧 **Multi-track audio** — keep every track while detecting the pauses from the
  first one, as an OBS recording with voice and system audio needs
- 📋 **Batch processing** with a queue, a live log and a run you can stop
- 🎛️ **Encoder controls** — CRF, frame rate, x264 preset and tune, audio rate,
  output container
- 🪟 **Compact progress mode** — a slim always-on-top strip for long batches
- 🌗 **Light, dark or system theme**, in **English, Italian, German, Spanish,
  French, Portuguese and Japanese**
- 📦 **FFmpeg included** — nothing to install

## Requirements

Nothing to install alongside it: FFmpeg ships with the app.

- **Windows:** 10 or newer, 64-bit.
- **Linux:** x86_64, with GTK 3 and `xdg-desktop-portal`, which every full
  desktop (GNOME, KDE, Xfce, ...) already has. Built and tested end to end
  on Ubuntu 22.04. On Ubuntu 24.04, Debian 12 and Fedora 41 only its
  libraries have been checked: they all load, but the app has not been run
  there yet.

### Building from source

Every platform needs Flutter 3.47 or newer, on the stable channel.

- **Windows:** Visual Studio 2022 with the *Desktop development with C++*
  workload. The steps, and packaging the installer, are in
  [docs/development.md](docs/development.md).
- **Linux:** clang, CMake, Ninja, GTK 3 headers, `patchelf`, and the codec
  libraries FFmpeg was linked against. The steps are in
  [docs/linux.md](docs/linux.md), which also explains how to build the Linux
  version from Windows with Docker.
- **macOS:** Xcode and CocoaPods; then `flutter run -d macos`. The macOS
  build is **not currently tested**.

```bash
git clone https://github.com/padvincenzo/silence-speedup
cd silence-speedup
flutter pub get
flutter run -d windows    # or: flutter run -d linux / -d macos
```

## Documentation

| Document | What is in it |
| --- | --- |
| [docs/usage.md](docs/usage.md) | Every setting, what it does, and how to fix a bad result |
| [docs/porting-notes.md](docs/porting-notes.md) | Coming from 2.x, why Flutter, and what changed from the Electron app |
| [docs/architecture.md](docs/architecture.md) | How the code is organised and why |
| [docs/ffmpeg-details.md](docs/ffmpeg-details.md) | The exact FFmpeg commands, flag by flag |
| [docs/development.md](docs/development.md) | Building, testing, releasing, extending |
| [docs/linux.md](docs/linux.md) | Building and trying the Linux version, from Windows too |
| [docs/microsoft-store.md](docs/microsoft-store.md) | For the maintainer: packaging and publishing the Store version |
| [ROADMAP.md](ROADMAP.md) | What is not built yet |
| [CLAUDE.md](CLAUDE.md) | Working rules for AI assistants in this repo |

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

## Privacy

Videos are processed on your computer and never leave it. There are no
accounts, no analytics and no tracking. The only connection the app makes is
the update check of the GitHub version, which reads the public list of
releases; the Store version does not make it. The details are in the
[privacy policy](https://www.vincenzopadula.it/silence-speedup-privacy-policy/).

## Licence

GPLv3 or later. Copyright (C) 2026 Vincenzo Padula.

This program comes with **absolutely no warranty**. It is free software, and you
are welcome to redistribute it under certain conditions; see [LICENSE](LICENSE).
