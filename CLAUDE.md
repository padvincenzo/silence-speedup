# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this project is

**Silence SpeedUp** is a desktop app that shortens videos by detecting silent
stretches and either speeding them up or cutting them out. FFmpeg does the
work; this app decides *what* to ask FFmpeg for.

From 3.0 on this repository is a **Flutter rewrite**. Versions 1.x and 2.x
were an Electron app, whose source is on the `archive/electron` branch;
treat it as the reference for intended behaviour, not as code to imitate.
The rewrite was developed in a separate repository, since deleted; its whole
history was joined to this one, so nothing of it is lost.

Primary target is **Windows**; **Linux** is built and tried from Windows in
Docker — see [docs/linux.md](docs/linux.md). **macOS** has a target, without
the app sandbox, and is not currently tested. Android is a deliberate future
target and the architecture is arranged for it — see [docs/architecture.md](docs/architecture.md).

## Commands

```bash
flutter pub get                     # after touching pubspec.yaml
flutter gen-l10n                    # after editing lib/l10n/arb/*.arb
flutter analyze                     # must be clean before committing
flutter test                        # unit tests, no encoder needed
flutter run -d windows              # debug run
flutter build windows --release     # release build
```

```powershell
.\installer\build-installer.ps1     # release build + Inno Setup package into dist\
.\installer\build-msix.ps1          # Store build (STORE_BUILD=true) + MSIX into dist\
.\installer\build-linux.ps1         # Linux: analyse, test, build, pack (Docker)
.\installer\build-linux.ps1 smoke   # Linux: start it on Xvfb, screenshot into dist\
.\installer\build-linux.ps1 e2e     # Linux: process a sample through the GUI, measure it
.\installer\build-linux.ps1 run     # Linux: show it on the desktop through WSLg
```

The first Windows build downloads prebuilt FFmpeg libraries; it is slow and
needs network. Later builds reuse them.

## Rules that matter here

### Work arrives on a branch, never straight on main

`main` is the published branch now that the repository is public, and what is
on it is what a stranger clones. Changes therefore go on a branch of their own
and wait: the author validates them and merges them by hand. Do not push a
code change to `main`, and do not merge your own branch.

The exception is **Markdown**. Documentation, the README, the roadmap and this
file can go straight to `main`, because a wrong sentence in a document costs a
reader a minute and a wrong flag in an encoder costs them a re-encode. That
holds only while the prose stands on its own: a document describing a change
that is still sitting on a branch travels **with** that branch, or it tells
readers about something their clone does not have.

### FFmpeg is bundled, never configured

FFmpeg comes from the `ffmpeg_kit_flutter_new` plugin (full-GPL, includes
`libx264`). **Do not** add a preference for an FFmpeg path, shell out to a
system `ffmpeg`, or ship a binary in `assets/`. The Electron app asked the user
to locate `ffmpeg.exe`; removing that was a deliberate product decision.

Everything that touches an encoder goes through the `FFmpegRunner` interface in
[lib/services/ffmpeg_runner.dart](lib/services/ffmpeg_runner.dart). Nothing else
in the app may import `ffmpeg_kit_flutter_new`.

### FFmpeg argument lists belong in FragmentPlanner

[lib/services/fragment_planner.dart](lib/services/fragment_planner.dart) is pure:
no I/O, no `BuildContext`, no progress plumbing. Every argument list the app
runs is built there and asserted in
[test/fragment_planner_test.dart](test/fragment_planner_test.dart) and
[test/preview_and_audio_test.dart](test/preview_and_audio_test.dart).

If you change how a fragment is encoded, change it there and add a test. A wrong
flag here produces a file that is subtly desynced rather than an error, so tests
are the only cheap way to catch it.

Four invariants that are easy to break:

- **Fragments must stay concat-compatible.** They are joined with `-c copy`, so
  every fragment needs the same codecs, container and frame rate. That is why
  `-fps_mode cfr` and the `fps` filter are on every fragment.
- **Muting keeps `atempo`.** When silences are muted, `volume=0` is *appended*
  to the tempo chain, not substituted for it. Dropping `atempo` leaves the audio
  longer than the sped-up video and desyncs everything downstream.
- **Stream mapping is explicit.** Fragments map `0:v:0?` plus either `0:a?`
  (all tracks) or `0:a:0?`, and the concat step maps `0`. Leave those out and
  FFmpeg's default selection silently keeps one audio track and drops the rest.
- **Detection always reads `0:a:0`.** Even when every track is exported, the
  pauses come from the first track — the voice track in a multi-track recording.

### The detected silences are shown, and they can go stale

[lib/ui/pages/silences_page.dart](lib/ui/pages/silences_page.dart) draws what
the detection found for one entry: a timeline, the figures, and the ranges
behind a closed heading. It is reached from a queue row once
`entry.hasSilences`, which is true after an analysis and after a finished run.

Two things it depends on:

- The timeline is zoomable, because the numbers that matter are small: at
  whole-video scale a tenth of a second is under a pixel. The view is a
  *window* — `SilenceTimelineController` holds a start and a span, and the
  painters map only that stretch onto the width. It is not a scaled-up canvas:
  seeing a tenth of a second in an hour needs a thousandfold magnification,
  and a canvas a thousand windows wide is not a thing to ask a compositor
  for. The controller is pure and tested; the gestures are not. The strip
  under the track is both the overview and the scrollbar — its marked part
  drags, and a press outside it jumps there — and `minimumSpan` is where the
  zoom stops: two seconds across the width, close enough to aim at a
  twentieth of a second and far enough to still see what surrounds it.
- The timeline and the figures do not scroll; only the list of ranges does.
  Pointing a row at the timeline is pointless if the pointing goes off
  screen, which is also why the list is not foldable: it is the substance of
  the page. The block above the list is a `Material` that lifts when the rows
  start passing under it, and that page's `AppBar` is given a
  `notificationPredicate` of false — an app bar takes the shadow for **any**
  scroll notification that reaches it, whether or not the content is going
  beneath it, and here it is not.
- `FragmentPlanner.outputSeconds` derives the estimated result from the same
  `plan` the run walks, so the figure and the file cannot disagree about what
  the settings mean. Anything else derived from a run belongs there too, and
  pure means testable.
- `MediaEntry.detectedWith` remembers the settings the ranges were found with,
  and `ProcessingSettings.detectsLike` says whether they still hold — only the
  threshold, the minimum duration and the margin can move a boundary. The page
  shows a notice rather than silently redrawing trimmed ranges against a
  margin that has since changed. Detection is not re-run on its own: on a long
  file that would be an unasked-for wait.

`_RangeTile` is where per-range editing will go. `setSilences` already takes a
replacement list, so that is a matter of building controls, not of changing the
model.

### The noise threshold is a measurement, not a taste

It is decibels below full scale — `thresholdDb`, negative, written into the
filter as `n=-34dB` — over the range `kThresholdDbMin`..`kThresholdDbMax`.
It used to be three named steps twenty decibels apart, and a setting saved
by that version is converted on load: the three were the amplitude ratios
0.002, 0.02 and 0.1, which are -54, -34 and -20 dB. `kNoiseAnchors` keeps
the names as what those numbers mean.

The number cannot be chosen by taste, because it depends on the recording.
`FragmentPlanner.levelArguments` measures a file with `astats` and
`parseLevels` reads the noise floor and the RMS out of what it printed —
taking the last of each, which is the `Overall` block rather than the first
channel. `AudioLevels.suggestedThresholdDb` is halfway between the two in
decibels, and `isUsable` is false when they are within 6 dB of each other,
because nothing separates a hiss as loud as the voice and offering a number
for it would be a pretence.

The measurement is not a run: `ProcessStore.measure` refuses while the
encoder is busy, touches no status and produces no file. It is stored on the
entry, and `prepare()` leaves it alone — it describes the file, and the file
does not change between runs.

It reads `FFmpegResult.output`, asked for with `collectOutput: true`, and
**not** the lines that reached `onLine`. Log messages are delivered
asynchronously and a session can complete with some still in flight, so a
filter that prints its findings as it closes — `astats` prints all of them
there — can have its entire output arrive after the run is over. Silence
detection reads its boundaries the same way, for the same reason. It used to
stream them, on the theory that `silencedetect` prints as it goes. On a short
file or a busy machine the session finished first anyway: a run kept one
silence out of six and reported success. Both read the collected log and the
streamed lines, and take whichever holds more. Anything else that reads what
FFmpeg *said* rather than what it wrote wants the same treatment.

It also says what it is doing: which file it is measuring, what it read, and
when it read nothing — in the log and on the tile. A measurement that
answered by putting its own button back was indistinguishable from a press
that never registered.

### Positions are absolute source seconds

`Fragment` and `SilenceRange` are in seconds from the start of the source file,
never relative to anything. A preview processes a `TimeWindow` rather than the
whole file, and `silencedetect` reports relative to its own seek, so
`buildRanges` adds the window's start back. Keep that conversion in one place.

### The version is bumped on every build

`version:` in [pubspec.yaml](pubspec.yaml) is the one place the version is
stated, and it is a plain `x.y.z` — **no `+build` suffix**. It ends up verbatim
in the executable's `FileVersion`, and `0.9.0+1` there reads like a leftover.

**Raise the patch number before every build that gets packaged or installed.**
Two builds must never carry the same version: the installer names its output
after it, the in-app update check compares against it, and a bug report that
says 0.9.4 has to mean one specific binary. A plain `x.y.z` also becomes the
`x.y.z.0` an MSIX package needs, which is the other reason there is no `+`.

### A release title starts with its version

Installed 2.x builds still check for updates, and they read this
repository's release feed: they take the **first** entry, pull the first
run of digits out of its title, and offer it if it is greater than their own.
So a release is titled `3.0.1` or `v3.0.1`, never a phrase with a year or
another number ahead of the version. A pre-release appears in the same feed,
so publishing one announces it to every 2.x user; its notes are what they
see in the update dialog.

### The GPL travels with the app

`LICENSE` is a declared asset, so the licence text the installer shows, the
one GitHub renders and the one [LicenseTextPage](lib/ui/pages/license_text_page.dart)
displays are the same file. The About page reads it in-app rather than opening
gnu.org: the app is required to carry the text, and every dependency's licence
is already readable without a browser.

The credits also state that the code was written with AI assistance, and — the
part a reader of that phrase actually wants — that the app contains no AI and
sends nothing anywhere. Keep both halves if you touch that wording.

### The privacy policy describes the code

A published privacy policy, at
<https://www.vincenzopadula.it/silence-speedup-privacy-policy/> and linked
from the README, the Store listing and the About page, says exactly what the app does with
data. Today that is three things: the GitHub build's one network request
(the release feed, absent from a Store build), the preferences file, and
temporary fragments that are deleted after a successful run. The log is
kept in memory only. Anything that adds to that list makes the policy
false: a new request, a new file kept on disk, a log written out. The
policy lives on the author's site, not in this repository, so say so
when proposing such a change, and the author will update it.

### A Store build is not allowed to update itself

The app has two channels, from this same source. GitHub releases carry a
free, unsigned Inno Setup installer for Windows and a bundle for Linux. The
Microsoft Store (Store ID 9NJ11SB1S9P5) sells the Windows version, signed and
kept up to date: a convenience, and a way to support the project.
`kStoreBuild` in [lib/build_config.dart](lib/build_config.dart) —
set with `--dart-define=STORE_BUILD=true` — switches the update check off,
because a Store app must not look for its own updates or point anyone at an
executable to download. Anything new that fetches or launches code has to
respect the same flag. Links to pages are fine.

Outside the Store the check **notifies and nothing more**: it says a newer
version exists and links to its page. Do not make it download or install.
Doing that on every operating system would be a project of its own, and
the Store already updates what it installs. The notice links to the
**release page on every platform**. Someone who chose the free installer is
not sent to the paid one. That was tried for one release and taken out.

The package is built by `installer/build-msix.ps1` from `msix_config` in
pubspec.yaml. Its identity fields are the ones Partner Center issued, and
the Store rejects a package whose identity differs from them by a single
character. The rest is in [docs/microsoft-store.md](docs/microsoft-store.md).

### Pages of text and settings are held to a readable width

`ReadableWidth` ([lib/ui/widgets/readable_width.dart](lib/ui/widgets/readable_width.dart))
centres a page and stops it at `kReadableWidth`. The about page and the app
settings use it: a window can be two thousand pixels across, and a row with a
label at one edge and its control at the other makes the eye cross the whole
monitor. The queue and the silence timeline deliberately do not — a working
list and a timeline both earn their width.

### Strings come from ARB, always

UI and log text is generated from `lib/l10n/arb/app_en.arb` (the template) and
one catalogue per translation — Italian, German, Spanish, French, European
Portuguese and Japanese — by `flutter gen-l10n`, configured in [l10n.yaml](l10n.yaml).

- In widgets: `AppLocalizations.of(context).someKey`.
- In services and stores: they hold a `LocaleController` and read
  `_locales.strings.someKey`, which needs no `BuildContext`.
- Model enums are turned into text only in [lib/l10n/labels.dart](lib/l10n/labels.dart),
  so `models/` never imports the generated class.
- **Add every new message to every catalogue, then run `flutter gen-l10n`.** A
  test asserts each translation has the template's keys and placeholders, so a
  missing translation fails the suite rather than silently falling back to
  English.
- The language picker lists `kLanguageNames` in
  [lib/l10n/locale_controller.dart](lib/l10n/locale_controller.dart), each
  language by its own name; a test asserts it names exactly the catalogues
  there are. A new language also goes into the installer's `[Languages]` and
  `msix_config.languages`.
- Use ARB placeholders and plurals rather than string concatenation. Numbers
  declared as `double` with `decimalPatternDigits` get a locale-correct decimal
  separator, which matters: Italian writes `12,50`, not `12.50`.
- The generated files in `lib/l10n/gen/` are committed so a fresh clone
  analyses without a codegen step. Regenerate them in the same commit as an ARB
  change; never hand-edit them.

### Language follows the system

[lib/l10n/locale_controller.dart](lib/l10n/locale_controller.dart) resolves the
first system language the app supports and falls back to English. A user can
pin one from App settings → Application, and "System" puts it back. `resolve`
takes an optional `systemLocales` so the order can be tested.

### The UI is Material, not a ported menu bar

`AppShell` is the frame: an `AppBar`, a `NavigationDrawer`, and one of three
pages (`lib/ui/pages/`). There is deliberately **no** `MenuBar` — do not
reintroduce one, and do not add a "File" or "View" menu. New actions go where
they belong:

- something you do to the queue → the queue's own toolbar, which carries the
  Add menu at one end and the clearing at the other, and nothing else;
- the one primary action of a screen → the floating action button;
- a setting that changes how a video is encoded → a tile in the right group of
  `EncodingSettingsView`, **with a description**, and an entry in that group's
  summary in [lib/l10n/labels.dart](lib/l10n/labels.dart);
- an action inside a settings surface → a `TextButton`, not a tile. A tile's
  title is `bodyLarge`, which makes it the largest text in the panel and
  louder than the group headings; the reset was one and read as a setting
  someone could switch on. If it cannot be undone, it asks first.
- a setting about the application itself → a tile on `AppSettingsPage`, again
  with a description, since both surfaces explain themselves in place;
- something application-level → the drawer.

The drawer's own button is on the queue only. A page the drawer sent you to
shows a back arrow to the queue instead: offering the drawer from inside
one of its own destinations is a way round rather than a way back.

### Encoding settings are a panel, application settings are a page

The two were one page once, and that made the settings people change between
runs as far away as the ones they set on the first day. They are separate now:

- `EncodingSettingsView` (`lib/ui/widgets/`) holds speed, audio, detection,
  export and preview, plus the reset that puts them back. It is shown docked
  to the right of the queue when the window is at least
  `kEncodingPanelBreakpoint` wide, and as an end-drawer side sheet when it is
  not. The app bar's button and Ctrl+, reach it; the sheet closes on Escape,
  the scrim, or its own button.
- **An open group's heading is pinned** while its own controls are on screen,
  and the next one pushes it off. That is why the panel is a `CustomScrollView`
  and `collapsibleGroupSlivers` returns slivers: a pinned header has to state
  its extent up front, which an open heading can do — it shows only its title,
  since the summary is for when the group is shut, and a shut group has nothing
  under it to stick above. Two things there are load-bearing:
  - each group's header and list go inside a **`SliverMainAxisGroup`**. Pinned
    slivers of a viewport *accumulate*; without the group, opening all five
    ends with five headings stacked at the top and no room for a control;
  - the pinned header must **fill** `kGroupHeaderHeight`. It reports its
    paint extent from what its child measures and its layout extent from the
    extent it declared, so a child that does not fill the height makes the
    two disagree and the framework asserts;
  - the shadow under a pinned heading comes from the group's own
    `scrollOffset`, read through a `SliverLayoutBuilder`. Not from
    `overlapsContent` — that means *another* pinned sliver is over this one,
    and it is false in the case that matters — and not from whether the panel
    has scrolled at all, which shadows every open heading including the ones
    still in the middle of the list with nothing beneath them.
- **The groups collapse, and a closed one shows only what differs from the
  default.** The summaries are the `*Changes` functions in
  [labels.dart](lib/l10n/labels.dart), each comparing against
  `const ProcessingSettings()` — never against a written-out copy of the
  defaults, which would go stale. A setting with no entry there is invisible
  once its group is closed, so adding one is part of adding a setting. Which
  groups are open is remembered in `PreferencesStore`; only the speeds start
  open.
- **The rates live on the button that opens the panel, and nowhere else.**
  They were also a chip on the queue, which meant two controls doing one job.
  Do not add a second indicator: if the app bar button needs to say more, say
  it there.

Keyboard shortcuts are declared in [lib/ui/shortcuts.dart](lib/ui/shortcuts.dart),
not where they are bound: the Add menu advertises two of them and the shell
implements them, and a menu that lies about a key is worse than a menu that
says nothing.

The app bar is down to two actions for the same reason — the encoding button
and the compact-progress one. The log toggle belongs to the status strip
beside the console it opens, and emptying the queue belongs to the queue's
toolbar; both were in the app bar as well, and one of each is enough. Tests
assert neither is there.
- Docking is remembered in `PreferencesStore.encodingPanelDocked`, so leaving
  the panel open is a durable choice rather than per-session state.
- `AppSettingsPage` (`lib/ui/pages/`) holds the theme, the language and the
  working directory, and is a drawer destination.

Neither one navigates away from the queue, which is the point: the list stays
where it is, and the settings arrive beside it.

Two pieces of chrome that were chosen against the framework's default:

- **The app bar lifts on a shadow, not a tint.** Material 3 tints the
  background once content scrolls under the bar, and folds that tint into the
  colour at build time — the elevation animates, the colour does not, so the
  bar changes shade in a single frame. `surfaceTintColor` is therefore
  transparent and `scrolledUnderElevation` does the work. Do not put the tint
  back; a test guards it.
- **The licences list is ours**, [lib/ui/pages/licenses_page.dart](lib/ui/pages/licenses_page.dart),
  not `showLicensePage`, for one reason: the framework's page scrolls the app
  name and version off the top and offers no way to keep them. Here they are a
  title that shrinks into a pinned bar, because a licence list has to say what
  it is a licence list of. The rest is deliberately the shape `showLicensePage`
  had — packages down the left, the document beside them above
  `kLicensesTwoPaneBreakpoint` and a route of its own below it — with the
  document framed and held to `kLicensesDocumentWidth`, since a licence line
  as wide as a monitor cannot be read. It reads `LicenseRegistry` directly, so
  a new dependency appears in it without anything being wired up.

- Anything that sits under the app bar on the queue screen is
  `kHeaderStripHeight` tall ([lib/ui/layout.dart](lib/ui/layout.dart)). The
  queue's toolbar and the encoding panel's title bar are side by side on a
  wide window, and built out of their own padding they came out four pixels
  apart.
- A message is shown with `showAppMessage`
  ([lib/ui/messages.dart](lib/ui/messages.dart)), never `showSnackBar`
  directly: it lays the snack bar out beside the Start button and stops short
  of it. Two things make that possible, and neither is obvious:
  - the button's own location ignores the snack bar's height, so the one
    control the screen is for does not jump because something was said;
  - **the body is a `Scaffold` of its own**, with `bodyMessengerKey`. A
    Scaffold anchors a floating snack bar to the *top* of its
    FloatingActionButton, so a message shown by the window's Scaffold can
    only ever appear above the button. The body has no button, so the
    message is laid against the bottom of the body — the line the button
    sits on. A negative bottom margin would be the other way, and `Padding`
    forbids one.
- **The strip under an app bar carries the scrolled-under shadow, not the
  app bar** — on the queue and on the silences page, where a toolbar or a
  heading sits in between. `ScrolledUnder`
  ([lib/ui/widgets/scrolled_under.dart](lib/ui/widgets/scrolled_under.dart))
  is that strip, and those app bars are given a `notificationPredicate` of
  false. An app bar takes the shadow for any scroll notification that
  reaches it, with no regard for whether the content is going beneath it.
  The settings and about pages scroll directly under their bar and keep the
  default.

Three layout constraints that are easy to undo:

- The queue's status strip is the Scaffold's `bottomNavigationBar`, not the last
  row of the page. That is what keeps the floating action button off the
  percentage readout, together with `kQueueBottomInset` on the list.
- Every readout that FFmpeg updates — the time, the speed, the percentage, in
  the status strip and in the compact one — holds room for its widest value
  and is right-aligned in it. Tabular figures alone are not enough: `9.00 %`
  and `10.00 %` differ by a character, and without the reserved width the
  whole row shuffles sideways several times a second.
- The compact strip is `kCompactContentHeight` tall, and the window it asks
  for is that **plus the title bar**, measured at the time — `setSize` covers
  the whole window, and assuming otherwise left the strip twenty pixels to
  draw in.
- With the panel docked, the floating action button is moved inwards by
  `_ShiftedFabLocation` so it floats over the queue and not over a setting.
- Every settings surface has to fit 640x480, the smallest window the app
  allows, and the encoding tiles also have to fit `kEncodingPanelWidth`. Tests
  assert both; that is why `DropdownSettingTile` puts its field under the label
  when it runs out of room.

`test/ui_smoke_test.dart` builds the shell and each page against a
`FakeFFmpegRunner` and fails on an overflow. Run it after touching the UI; it
is the only thing watching the layout.

### State lives in four stores

`PreferencesStore`, `QueueStore`, `ProcessStore`, `LogStore` — all
`ChangeNotifier`, wired up in [lib/main.dart](lib/main.dart) and read with
`provider`. `ProcessStore` is the only thing that starts a run and the only
thing that locks the queue; widgets never reason about who may change what.

### One copy at a time

Two copies of the app share what cannot be shared: the scratch directory the
fragments are written to, and the preferences file, which each rewrites whole
from whatever it loaded at startup. The second one to close therefore wins,
silently.

`windows/runner/single_instance.cpp` holds a named mutex for the life of the
process and, when it finds one already held, brings the running window
forward and returns before an engine is started — so a second launch shows
nothing and costs nothing. It identifies the other window by class *and* by
the executable behind it: every Flutter app answers to
`FLUTTER_RUNNER_WIN32_WINDOW`, so the class alone would find the wrong one.

This is native on purpose. It has to run before a window could appear, and
bringing another process forward is a Win32 errand either way. Android needs
none of it; its launcher already reuses the task.

On Linux the same rule rests on the session bus. The GTK application is
registered as unique, without the template's `G_APPLICATION_NON_UNIQUE`, so a
second launch hands its activation to the first copy and exits, and
`my_application_activate` presents the window that already exists instead
of opening another. `build-linux.ps1 smoke` checks it.

### On Linux, FFmpeg's libraries travel with it

The plugin's Linux FFmpeg is linked against the codec libraries of the
distribution it was built on (libvpx, x265, xvid, libass…), under that
distribution's sonames, and nothing points the loader at the bundle.
[linux/bundle-ffmpeg-libraries.sh](linux/bundle-ffmpeg-libraries.sh), run by
the install step in `linux/CMakeLists.txt`, copies those libraries into the
bundle and gives every one of them, and the plugin, `RUNPATH=$ORIGIN`.
Without it the window opens and FFmpeg silently fails to load, which is the
"locate FFmpeg yourself" this app removed, reached by another route. The
script's `baseline` is the list of what a desktop is trusted to have. Keep it
short: a library goes there only when its soname has held for years on every
distribution. `libgomp` was on it once and a clean Ubuntu 24.04 lacked it.

### File dialogs can be missing

Open them through [lib/ui/file_dialogs.dart](lib/ui/file_dialogs.dart), never
`FilePicker` directly. On Linux the dialog comes from the XDG desktop
portal, and a desktop without one makes `file_picker` throw. Thrown from a
button press, that exception reached nobody, and the press looked ignored.
The helpers answer null and show a message instead.

### Output and scratch space are separate

The export folder can follow each source file, so there is no single output
directory. `PreferencesStore.outputDirectoryFor(entry)` answers per entry, and
the engine takes that resolver rather than a path. Intermediate fragments go to
`PreferencesStore.workingDirectory` (system temp by default), never under the
export folder.

The destination is chosen in the encoding settings, in the Export group beside
the container and the quality — it is a setting about exporting. It is not part
of `ProcessingSettings` (it is a preference of its own), which is why that
group's collapsed summary is assembled at the call site rather than in
`exportChanges`.

### Code style

- Explicit types on locals, fields and collection literals. The codebase reads
  `final List<String> paths = <String>[]`, not `var paths = []`. Match it.
- Comments explain *why*, and are worth writing where a reader would otherwise
  wonder. Do not narrate what the next line does.
- `flutter analyze` clean, no new `// ignore:`. `prefer_initializing_formals` is
  off project-wide with a reason stated in `analysis_options.yaml`.

## Where things are

```
lib/
├── main.dart               # bootstrap: prefs → locale → window → stores
├── app.dart                # MaterialApp, theme, locale
├── l10n/
│   ├── arb/                # app_en.arb (template), one per translation
│   ├── gen/                # generated, committed, never hand-edited
│   ├── locale_controller.dart
│   └── labels.dart         # enum → text, the only bridge from models/
├── models/
│   ├── options.dart        # option catalogues (was config.json)
│   ├── processing_settings.dart
│   ├── media_entry.dart
│   └── time_window.dart
├── services/
│   ├── ffmpeg_runner.dart     # the only door to FFmpeg
│   ├── fragment_planner.dart  # pure argument construction
│   ├── speedup_engine.dart    # sequencing, progress, I/O
│   ├── app_paths.dart         # the part Android will have to change
│   └── update_checker.dart
├── state/                  # the four stores
└── ui/
    ├── app_shell.dart      # app bar, drawer, encoding panel, destinations
    ├── theme.dart          # one ThemeData for both brightnesses
    ├── pages/              # queue, app settings, about
    └── widgets/            # incl. the encoding settings view and panel
installer/                  # Inno Setup script + build script
```

## Deliberate differences from the Electron app

These are fixes, not oversights. Do not "restore" them; see
[docs/porting-notes.md](docs/porting-notes.md) for the full list with reasoning.

- The silence margin applies to **every** detected range. The original skipped
  the first boundary of each list.
- Muting a silence chains `volume=0` onto `atempo` instead of replacing it.
- Every audio track can be carried through; the original always kept one.
- Output files never overwrite: a name collision gets ` (1)` appended. This
  matters more now that the export folder can be the source folder.
- Temporary fragments live outside the export folder, are per-run, and are
  deleted after a successful run.
- Version comparison is per-component, not "strip the dots and parse".

## Not implemented yet

The demo player — a live preview that *plays* a file with the silences sped up
as you watch — is not ported. The per-file preview action is a different thing:
it encodes a short sample through the real pipeline. The live player is the main
open item in [ROADMAP.md](ROADMAP.md); do not start it without asking, as it
pulls in a video playback stack.
