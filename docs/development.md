# Development

## Prerequisites

- **Flutter** 3.47 or newer, on the stable channel (Dart 3.13+).
- **Windows**: Visual Studio 2022 with the *Desktop development with C++*
  workload. `flutter doctor` will say if it is missing.
- **Linux**: a toolchain and a list of libraries of its own, described in
  [linux.md](linux.md), together with how to build the Linux version from
  Windows in Docker.
- **macOS**: Xcode and CocoaPods, then `flutter run -d macos`. The macOS
  build is **not currently tested**.
- Network access for the **first** build. The FFmpeg libraries are
  downloaded then.

```bash
flutter doctor -v      # confirm the toolchain is green
```

## Running

```bash
git clone https://github.com/padvincenzo/silence-speedup
cd silence-speedup
flutter pub get
flutter run -d windows
```

## Everyday commands

| Command | What it does |
| --- | --- |
| `flutter gen-l10n` | Regenerates `lib/l10n/gen/` from the ARB catalogues. Run it after editing them. |
| `flutter analyze` | Static analysis. Must be clean before committing. |
| `flutter test` | Unit tests. No encoder or media files needed; runs in seconds. |
| `flutter run -d windows` | Debug run with hot reload. |
| `flutter build windows --release` | Release build into `build/windows/x64/runner/Release/`. |
| `dart format lib test` | Formatting. |

## How FFmpeg gets into the build

`ffmpeg_kit_flutter_new` fetches prebuilt **full-GPL FFmpeg 8.1.2** libraries at
build time and copies them next to the executable. After a release build you
should see them in the output directory:

```
build/windows/x64/runner/Release/
    silence_speedup.exe
    libffmpegkit.dll
    avcodec-62.dll  avformat-62.dll  avfilter-11.dll  avutil-60.dll ...
    libx264-165.dll        ← the GPL encoder every fragment uses
```

If `libx264-*.dll` is absent, the plugin variant is wrong and every export will
fail: the app encodes exclusively with `libx264`.

To build against a locally compiled FFmpeg bundle instead, set
`FFMPEGKIT_LOCAL_DIR` to the bundle directory before running the build.

The first build is slow because of the download. Subsequent builds reuse it;
`flutter clean` throws it away.

## The app icon

These files are generated from `assets/icons/icon.svg`, the 600px original,
and they have to stay in step:

| File | Used for | Sizes |
| --- | --- | --- |
| `windows/runner/resources/app_icon.ico` | the executable, its window and its taskbar button | 16-256 |
| `assets/icons/icon.ico` | `SetupIconFile` in the Inno Setup script | 16-256 |
| `assets/icons/icon.png` | drawn by the interface itself, in the drawer and the about page | 256 |
| `installer/msix/logo.png` | source the MSIX tool derives Store tiles from | 1024 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png` | the macOS app bundle | 16-1024 |

Linux has no file of its own: the runner sets the window icon from the
bundled `assets/icons/icon.png`.

Resample each size from the vector separately rather than letting an icon
writer downscale one bitmap: 16x16 is where the difference shows. For the
PNGs, `rsvg-convert -w N -h N -a assets/icons/icon.svg -o out.png` does
that. ImageMagick can only read the SVG through it anyway.

**After changing the icon, Windows will keep showing the old one.** The
executable is right — `[System.Drawing.Icon]::ExtractAssociatedIcon` reads the
resource and will say so — but the shell caches icons per executable path in
`%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db`, and the path
does not change when the file does. `ie4uinit.exe -show` asks for a refresh;
Explorer also holds a copy in memory, so the reliable fixes are restarting
`explorer.exe` or simply signing in again. Do not go looking for a build
problem that is not there.

## Project layout

```
silence-speedup/
├── CLAUDE.md            # working rules for AI assistants
├── ROADMAP.md           # what is not built yet
├── analysis_options.yaml
├── l10n.yaml            # gen-l10n configuration
├── assets/
│   └── icons/           # app icon (shared with the Electron app)
├── docs/
├── installer/           # Inno Setup script + build-installer.ps1
├── lib/
│   ├── main.dart        # bootstrap: translations → prefs → window → stores
│   ├── app.dart         # MaterialApp, theme, locale
│   ├── l10n/            # ARB catalogues, generated class, locale controller
│   ├── models/          # options catalogue, settings, queue entry
│   ├── services/        # FFmpeg boundary, planner, engine, paths, updates
│   ├── state/           # the four ChangeNotifier stores
│   └── ui/              # app_shell + pages/ + widgets/
├── test/
├── windows/             # Flutter desktop runner
└── android/             # scaffolded; UI not built yet (see ROADMAP)
```

[architecture.md](architecture.md) explains why the layers are arranged this way.

## Testing

Tests cover the pure core — the FFmpeg argument lists and the range/fragment
geometry — because that is where a mistake produces a *plausible but wrong*
file rather than an error:

- [test/fragment_planner_test.dart](../test/fragment_planner_test.dart) —
  boundary pairing, margin trimming, fragment planning, every argument list,
  concat-list escaping.
- [test/preview_and_audio_test.dart](../test/preview_and_audio_test.dart) —
  the preview window's placement, detection over a window, stream mapping for
  one or many audio tracks, preview output naming.
- [test/settings_and_update_test.dart](../test/settings_and_update_test.dart) —
  settings serialisation and clamping, the speed catalogue's internal
  consistency, entry naming, version comparison.
- [test/localization_test.dart](../test/localization_test.dart) — language
  resolution, that every translation covers the template's keys and keeps its
  placeholders, that no value was left in English, and that placeholders and locale-aware
  number formatting work.

When adding a feature that changes what FFmpeg is asked to do, add the assertion
to `fragment_planner_test.dart` in the same commit. It is much cheaper than
noticing the drift in an exported file a week later.

- [test/ui_smoke_test.dart](../test/ui_smoke_test.dart) — builds the shell and
  each page against a fake `FFmpegRunner`, navigates the drawer, checks the
  settings surfaces fit the smallest allowed window — and the encoding tiles
  the panel width — and renders them in Italian.
  This is the safety net for a UI nobody is looking at while the tests run: a
  layout overflow surfaces as a test failure rather than as a red stripe
  somebody notices later.

There is no end-to-end test that drives a real encode — see
[ROADMAP.md](../ROADMAP.md).

### Manual checks worth doing before a release

The pipeline touches real files, so a few things only a real run will show:

1. A file whose **first** sound starts after a pause (checks the margin on the
   first range).
2. A file that **fades out into silence** (checks the unclosed final boundary).
3. **Silence speed = Remove** (checks that silent fragments are skipped, not
   emitted empty).
4. **Mute silences** on, at 8× (checks A/V stays in sync to the end).
5. **Stop** mid-run (checks the row is marked interrupted and fragments are
   kept).
6. A **format change**, e.g. `.mov` in, MP4 out.
7. A path containing **spaces and an apostrophe** (checks concat-list escaping).
8. Two runs of the same file into the same folder (checks ` (1)` naming).
9. A **multi-track** recording with **Keep all audio tracks** on, e.g. an OBS
   capture with voice on track 1 and system audio on track 2 (checks that both
   tracks survive and stay in sync, and that only track 1 drove the cuts).
10. A **preview** on a long file (checks the sample is taken from the middle,
    not the start) and on a file shorter than the preview length.
11. The app with the system language set to one of its translations, and with
    it set to something the app does not have (should fall back to English).

## Adding to the app

### A new setting

1. Add the field to `ProcessingSettings`, with a default, a `copyWith` entry and
   `toJson` / `fromJson` handling. Clamp it in `fromJson`: a stale preferences
   file must never crash the app.
2. If it changes the FFmpeg call, change `FragmentPlanner` and add a test.
3. Add a tile to the right group in `EncodingSettingsView` — or to
   `AppSettingsPage` if it is about the application rather than the encoding —
   and give it a description: every setting explains itself in place.
4. Add it to that group's summary function in `lib/l10n/labels.dart`, so a
   value that is no longer the default is visible while the group is closed.
   Compare against `const ProcessingSettings()`, never against a copy of the
   defaults written out by hand.
5. Add the label — and the tooltip, if the effect is not obvious — to **both**
   ARB catalogues, then run `flutter gen-l10n`.

### A new option in a catalogue

Append to the list in `lib/models/options.dart`. Indexes are persisted, so
**appending is safe but reordering is not** — a reorder silently changes what
existing users have selected. `ProcessingSettings.fromJson` clamps out-of-range
indexes, so shrinking a list is safe.

### A new message

1. Add it to `lib/l10n/arb/app_en.arb` — the template — with an `@`-entry
   declaring any placeholders.
2. Add the translation to every other `app_<code>.arb`. A test fails if you
   forget one.
3. `flutter gen-l10n`, and commit the regenerated files alongside the ARB
   change.

Prefer ARB placeholders and plurals over building strings in Dart: numbers
declared as `double` with `decimalPatternDigits` come out with the right decimal
separator per language, which string interpolation cannot do.

### A new language

1. Copy `lib/l10n/arb/app_en.arb` to `app_<code>.arb`, change `@@locale`, and
   translate the values.
2. `flutter gen-l10n` — the locale is picked up automatically and appears in
   `AppLocalizations.supportedLocales`.
3. Add the language, by its own name, to `kLanguageNames` in
   `lib/l10n/locale_controller.dart`; a test fails until the picker and the
   catalogues agree.
4. Add it to `[Languages]` in `installer/silence-speedup.iss` and to
   `msix_config.languages` in `pubspec.yaml`.

Missing keys fall back to the template, so a partial translation degrades rather
than breaks — but the ARB test will flag it.

## Releasing

1. Bump `version:` in `pubspec.yaml` — the one place the version is stated.
   Raise the patch number for **every** build that leaves the machine, and
   keep it a plain `x.y.z`: the string goes straight into the executable's
   `FileVersion`, and a `+build` suffix there is noise. Two binaries with the
   same version cannot be told apart afterwards.
2. `flutter analyze && flutter test`.
3. Build and package:

   ```powershell
   .\installer\build-installer.ps1
   ```

   It reads the version from `pubspec.yaml`, runs the release build, checks
   that `libx264-*.dll` made it into the output, and writes
   `dist/SilenceSpeedUp-<version>-windows-x64-setup.exe`.

   Pass `-SkipBuild` to package a build that already exists, and `-IsccPath`
   if Inno Setup lives somewhere unusual. Install Inno Setup with:

   ```powershell
   winget install --id JRSoftware.InnoSetup --source winget
   ```

   A plain zip of `build/windows/x64/runner/Release/` also works as a
   portable release, as long as the whole folder is included — the FFmpeg
   DLLs beside the executable are required.
4. Build the Linux bundle, and check it, with Docker Desktop:

   ```powershell
   .\installer\build-linux.ps1
   .\installer\build-linux.ps1 e2e
   ```

   This writes `dist/silence-speedup-<version>-linux-x64.tar.gz`. See
   [linux.md](linux.md).
5. Publish a GitHub release with the Windows installer and the Linux bundle
   attached. **The title must begin with the version**, `3.0.1` or `v3.0.1`.
   Both the app and the installed 2.x Electron builds read the repository's
   `releases.atom`, take the newest entry, and pull the version out of its
   title. A pre-release appears in that feed too, so publishing one announces
   it to everyone.
6. Build the Store package and upload it in Partner Center:

   ```powershell
   .\installer\build-msix.ps1
   ```

   See [microsoft-store.md](microsoft-store.md). The Store refuses a version
   it has already seen, which is one more reason the patch number rises for
   every build.

Because FFmpeg is bundled under the GPL, releases must keep carrying the GPLv3
notice and offer the corresponding source.

## Contributing

Issues and pull requests: <https://github.com/padvincenzo/silence-speedup>

Before opening a PR: `flutter analyze` clean, `flutter test` green, and new
FFmpeg behaviour covered by a test. Read [porting-notes.md](porting-notes.md)
first if the change touches the pipeline — several apparent oddities are
deliberate fixes to the Electron version.
