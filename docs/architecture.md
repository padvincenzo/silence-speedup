# Architecture

How the app is put together, and why it is put together that way.

---

## The shape of the problem

The app has one job: given a media file and some settings, produce a shorter
copy of it. Everything hard about that job lives in FFmpeg. What the app
contributes is:

1. Deciding **where** the silences are.
2. Deciding **what rate** each stretch should play at.
3. Building the FFmpeg invocations that realise those decisions.
4. Sequencing dozens of invocations while showing honest progress and staying
   interruptible.

Steps 1–3 are pure computation over numbers and strings. Step 4 is all I/O,
timing and cancellation. The codebase is split along exactly that seam, because
step 3 is where mistakes are expensive and invisible — a wrong flag yields a
file that plays but drifts out of sync — and pure code is the only kind you can
cheaply assert against.

---

## Layers

```
        ┌─────────────────────────────────────────────┐
  UI    │  home_page · widgets/ · dialogs/            │
        │  reads stores, calls stores, renders        │
        └───────────────────┬─────────────────────────┘
                            │ provider
        ┌───────────────────┴─────────────────────────┐
 State  │  PreferencesStore  QueueStore               │
        │  ProcessStore      LogStore                 │
        └───────────────────┬─────────────────────────┘
                            │
        ┌───────────────────┴─────────────────────────┐
Service │  SpeedupEngine ──── sequencing, progress    │
        │       │                                     │
        │       ├── FragmentPlanner  (pure)           │
        │       └── FFmpegRunner     (interface)      │
        └───────────────────┬─────────────────────────┘
                            │
        ┌───────────────────┴─────────────────────────┐
Platform│  FFmpegKitRunner → ffmpeg_kit_flutter_new   │
        │  AppPaths        → filesystem locations     │
        └─────────────────────────────────────────────┘
```

Dependencies point downward only. A widget never imports a platform package;
the engine never imports a widget.

---

## The FFmpeg boundary

`FFmpegRunner` ([lib/services/ffmpeg_runner.dart](../lib/services/ffmpeg_runner.dart))
is the app's entire dependency on FFmpeg, expressed as three operations:

```dart
abstract class FFmpegRunner {
  Future<Duration?> probeDuration(String path);
  Future<FFmpegResult> run(List<String> arguments, {onLine, onProgress});
  Future<void> cancel();
}
```

`FFmpegKitRunner` implements it over `ffmpeg_kit_flutter_new`. **Nothing else in
the app imports that package.** Two things follow:

- **The Android port is a UI-and-storage problem, not an encoding problem.** The
  plugin already runs on Android, iOS, macOS, Windows and Linux behind one
  API, so the engine, the planner and the models are already portable. What
  needs replacing is the desktop chrome (drag-and-drop, the resizable window,
  the compact always-on-top strip) and `AppPaths`, since an Android app cannot
  write to an arbitrary folder in the user's home. Single-instance
  enforcement is desktop chrome too — it lives in the Windows runner, and
  Android's launcher already reuses the task. The navigation drawer, the
  settings page and the encoding panel — which already becomes a side sheet
  below `kEncodingPanelBreakpoint` — all work on a phone.
- **A fake runner can drive the whole engine** without an encoder present.

### Why bundled, not a system binary

The Electron app asked the user to point a preference at `ffmpeg.exe`, and
refused to work until they did. That is a support burden and a bad first run.
The plugin ships a full-GPL FFmpeg build (which is what provides `libx264`), so
there is no path to configure and no binary in `assets/`. Windows libraries are
fetched at build time; see [development.md](development.md).

### Log parsing

FFmpeg's log callback fires once per `av_log` write, which is **not** reliably
one line. `FFmpegKitRunner` buffers partial output and only hands complete lines
to `onLine`, so the `silence_start` / `silence_end` regex never sees half a
number. The remainder is flushed when the session ends.

---

## The pure core: FragmentPlanner

[lib/services/fragment_planner.dart](../lib/services/fragment_planner.dart)
holds every FFmpeg argument list the app runs, plus the two pieces of geometry
that decide what gets encoded:

| Function | Responsibility |
| --- | --- |
| `detectArguments` | The `silencedetect` pass, over the whole file or one window |
| `buildRanges` | Pair up boundaries, apply the margin, make positions absolute |
| `plan` | Walk a stretch of the timeline into alternating fragments |
| `exportArguments` | Encode one fragment at its rate |
| `concatArguments` | Join the fragments without re-encoding |
| `concatListEntry` | One line of the concat list file, correctly escaped |

No I/O, no `BuildContext`, no clock. All of it is asserted in
[test/fragment_planner_test.dart](../test/fragment_planner_test.dart) and
[test/preview_and_audio_test.dart](../test/preview_and_audio_test.dart).

### The concat invariant

Fragments are joined with `-c:a copy -c:v copy` — no re-encoding, which is what
makes the join fast. The price is that **every fragment must be
interchangeable**: same codecs, same container, same frame rate. That is why:

- `-c:v libx264 -c:a aac` are fixed rather than user-selectable;
- the `fps` filter is applied to *every* fragment, sped-up or not;
- `-vsync cfr` is on every fragment;
- fragments use the *output* container's extension, not the input's.

Break any of those and the concat step either fails or produces a file whose
audio drifts. If you need a genuinely different encode per fragment, the concat
step has to become a re-encode, which is a much bigger change.

### Stream mapping is explicit

Fragments map `0:v:0?` plus either `0:a:0?` or, with **Keep all audio tracks**
on, `0:a?`; the concat step maps `0`. Leave any of that out and FFmpeg's default
stream selection keeps one audio track and silently drops the others — which is
exactly how a multi-track recording loses its second track.

Detection is the exception that proves the rule: it always reads `0:a:0`, even
when every track is being exported. In a multi-track recording the first track
is the voice, and only the voice should decide where the pauses are.

### Positions are absolute source seconds

`Fragment` and `SilenceRange` always count from the start of the source file. A
preview processes a `TimeWindow` instead of the whole thing, and `silencedetect`
reports relative to its own seek, so `buildRanges` adds the window's start back
and clamps to it. That is the one place the conversion happens; the plan, the
arguments and the progress arithmetic are all unaware that a run might be
partial.

---

## The sequencer: SpeedupEngine

[lib/services/speedup_engine.dart](../lib/services/speedup_engine.dart) owns
what the planner deliberately does not: order, progress, the filesystem, and
stopping.

Per entry:

```
probe duration ─→ detect silences ─→ plan ─→ encode each fragment ─→ concat
                        │                                              │
                   no silences?                                   output path
                   mark done, next                             resolved to a free name
```

### Progress is corrected for playback rate

FFmpeg reports the position it has reached in the **output** stream. A 10-second
silence encoded at 8x produces 1.25 seconds of output, so taking that number at
face value makes the bar crawl. The engine scales it back by the fragment's rate:

```dart
sourceSeconds = fragment.start + outputSeconds * speed.factor;
```

which is why `SpeedOption` carries a numeric `factor` alongside its label, and
why a test asserts that the two agree for every option.

### Stopping

`stop()` sets a flag *and* cancels the running FFmpeg session. Every loop in the
engine checks the flag between steps, and every `run` result is inspected for
`cancelled`. Without both, a stop would either be ignored until the current
fragment finished or would be reported as a failure.

### Scratch space

Each entry gets its own directory under the configured working directory,
`run_<microseconds>/`, which defaults to a folder in the system temp directory.
It is deliberately not under the export folder: that folder can follow each
source file, so there is nowhere single under it to put fragments.
Per-run isolation means a leftover from an interrupted run, or from an older
version of the app, cannot end up in this concatenation. The directory is
deleted after a successful run and **kept after a failure**, since the fragments
are the only evidence of what went wrong; the log says where they are.

---

## State

Four `ChangeNotifier` stores, constructed in
[lib/main.dart](../lib/main.dart) and exposed with `provider`:

| Store | Owns |
| --- | --- |
| `PreferencesStore` | Export destination, working directory, theme, language, processing settings — everything persisted |
| `QueueStore` | The list of files, their probe results, whether importing is allowed |
| `ProcessStore` | Whether a run is active, its progress, compact-window mode |
| `LogStore` | The log lines behind the terminal button |

`ProcessStore` is the only thing that starts a run and the only thing that locks
the queue. Widgets ask it questions (`canStart`, `isRunning`) rather than
working out for themselves whether an action is currently legal.

`MediaEntry` is *also* a `ChangeNotifier`, provided per row. A row rebuilds when
its own entry changes, so a status update during a long run does not rebuild the
whole list.

---

## Localization

Messages live in ARB catalogues under `lib/l10n/arb/` and are compiled by
`flutter gen-l10n` into a typed `AppLocalizations`. Typed matters: a renamed or
missing message becomes a compile error rather than a string that quietly
renders as its own key.

Three ways in, by layer:

- **Widgets** — `AppLocalizations.of(context).someKey`, which rebuilds them when
  the language changes.
- **Services and stores** — they hold a `LocaleController` and read
  `strings.someKey`. The engine logs translated messages from deep inside async
  work where there is no `BuildContext`, which is why the controller keeps an
  `AppLocalizations` of its own, loaded through the delegate.
- **Model enums** — resolved only in `lib/l10n/labels.dart`, so `models/` never
  imports the generated class. Each switch there is exhaustive, so adding an
  enum value breaks the build instead of rendering nothing.

`LocaleController` decides the language: the first system language the app
supports, English otherwise. A choice pinned from Settings → Application overrides that
until the user picks "System" again, and `didChangeLocales` re-resolves if the
OS language changes while the app is running.

Formatting goes through ARB as well — plurals for counts, and `double`
placeholders with `decimalPatternDigits` for percentages, so Italian reads
`12,50` rather than `12.50`. String concatenation would lose both.

The generated files in `lib/l10n/gen/` are committed, so a fresh clone analyses
without a codegen step.

## Where output goes

The export folder can follow each source file, so there is no single output
directory to hand the engine. `PreferencesStore.outputDirectoryFor(entry)`
answers per entry, and the engine takes that resolver rather than a path — the
same seam that will let Android answer with a MediaStore location instead.

---

## The shape of the UI

`AppShell` is the frame: an `AppBar`, a `NavigationDrawer`, and one of three
pages — queue, settings, about.

There is no menu bar. A File / Media / View / Help bar is a desktop-toolkit
idiom that Material has no equivalent for, and most of what the Electron
version kept in it was not navigation anyway:

| Was in the menu | Is now |
| --- | --- |
| Open video(s) / folder | Buttons on the queue, plus the same shortcuts |
| Start / Stop | The floating action button — the one thing the screen is for |
| Settings, Preferences | The encoding panel beside the queue, from the rate chip, the app bar or Ctrl+, |
| Theme, Language | The app settings page, a drawer destination |
| Progress mode, log, clear queue | App bar actions on the queue |
| About, Licence, links, Quit | The drawer's lower half |

Two consequences worth knowing:

- **The status strip is a `bottomNavigationBar`, not the last row of the page.**
  Material floats the action button above a bottom bar, so putting the progress
  readouts there is what keeps the button from sitting on top of the
  percentage. `EntryList` adds `kQueueBottomInset` of bottom padding for the
  same reason.
- **Settings explain themselves in place.** Each row carries its description as
  a visible subtitle. The Electron modal had the same sentences behind a help
  icon, where nobody read them; a page has room to simply say what a setting
  does, which is the difference between a control people adjust and one they
  leave alone.

The compact progress bar is a *mode* of the single window rather than a second
one: `ProcessStore.compactMode` flips the widget tree, and `AppShell` reconciles
the OS window — size, resizability, always-on-top — in a post-frame callback,
restoring the previous size on the way back.

Because the UI cannot be checked by eye from a test suite,
[test/ui_smoke_test.dart](../test/ui_smoke_test.dart) builds the shell and each
page against a `FakeFFmpegRunner`, navigates the drawer, and asserts nothing
overflows at the smallest window size the app allows.
