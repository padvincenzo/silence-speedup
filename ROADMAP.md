# Roadmap

What is not built yet, roughly in the order it is worth building.

The Flutter port reproduces the Electron app's processing pipeline and its
desktop UI. The items below are the gaps, plus the directions the rewrite was
arranged to make possible.

---

## 1. Live demo player

**The one feature from the Electron app that is not ported.**

The original had a per-file *demo* button: it ran the detection pass, then opened
a [video.js](https://videojs.com/) window with the
[`videojs-silence-speedup`](https://www.npmjs.com/package/videojs-silence-speedup)
plugin, which played the file live — jumping the playback rate up during the
detected silences and back down for speech. It let you *hear* your settings
before spending twenty minutes encoding.

Two things in the port cover part of its role:

- **Generate a short preview sample** encodes a stretch of the video through the
  real pipeline and opens it. This does answer "does this sound right" — for
  that stretch, and after a short encode.
- **Measure the silences without exporting** reports the percentage of silence
  found in seconds. That answers "are my thresholds sane".

What is still missing is the immediacy: scrubbing through the *whole* file and
hearing the effect live, with no encode at all, and being able to change a
setting and hear the difference at once.

### What it needs

Desktop video playback with a controllable playback rate.
[`media_kit`](https://pub.dev/packages/media_kit) is the realistic option:
`video_player` has no first-class Windows support, and `media_kit` exposes
`setRate` plus reliable position events, which is exactly the pair required.

### Sketch

```dart
// The detection pass already yields List<SilenceRange> on the entry.
// Playback then only has to switch rate at the boundaries:
player.stream.position.listen((Duration position) {
  final bool inSilence = ranges.any((SilenceRange r) =>
      position.inMilliseconds / 1000 >= r.start &&
      position.inMilliseconds / 1000 < r.end);
  final double target = inSilence
      ? settings.silenceSpeed.factor
      : settings.playbackSpeed.factor;
  if (target != currentRate) player.setRate(target);
});
```

The pieces it can reuse: `SilenceRange` and the detection pass as they are, and
`SpeedOption.factor`, which already carries the numeric rate for exactly this
kind of use.

### Open questions

- **Removed silences.** When the silence speed is Remove, should the player seek
  past them, or play them at some high rate as a preview? Seeking is truer to
  the output but makes the preview jumpy.
- **Muting.** `volume=0` on silences would need to be mirrored by muting the
  player at the boundaries.
- **Weight.** `media_kit` pulls in native libmpv per platform, on top of the
  FFmpeg the app already bundles. Worth measuring the size cost before
  committing.

### Cost

The largest item on this list: a new window/route, a new native dependency, and
rate-switching that has to be smooth enough to be useful. Do not start it
without agreeing the scope first — and weigh it against the preview sample,
which already covers much of the need at a fraction of the complexity.

---

## 2. Working with the cuts

The detection gets most pauses right and some wrong — a breath taken for
speech, a short word lost in a pause — and the only remedy today is to change
a setting and run again. These three make the cuts something to work with.

- **Export the cuts instead of a video.** Write the plan as an edit list —
  FCPXML for Final Cut and DaVinci Resolve, Premiere XML, EDL, and an MLT
  project for Kdenlive and Shotcut — so an editor gets a rough cut to refine
  rather than a finished file. It is the feature most often asked of tools
  like this one: among the most upvoted requests in auto-editor's issue
  tracker, on the Shotcut forum, and in discussions of Recut. It needs no
  encoding at all: the fragments are already in `FragmentPlanner.plan`, so
  this is serialisation, and each format wants a test against a file the
  editor itself accepts.
- **Edit the detected silences.** On the silences page, per range: drop it,
  so it plays as speech, or move its boundaries. `_RangeTile` is where the
  controls go, and `MediaEntry.setSilences` already takes a replacement list,
  so that much needs no change to the model. Choosing per range between
  speeding up and cutting does: `SilenceRange` holds only a start and an end,
  and the plan takes the rate from the settings. What also needs deciding is
  what a re-detection does to hand edits — discard them, after asking.
- **Separate margins before and after a pause.** One margin is kept on both
  sides of every silence today, but the two edges are not alike: a sentence
  can fade out below the threshold, or begin on a consonant that cuts in
  sharply. A margin for each edge lets one stay tight where the other needs
  room. `buildRanges` applies the margin, and `detectsLike` has to compare
  both.

---

## 3. Android

The FFmpeg layer already runs there: `ffmpeg_kit_flutter_new` supports Android,
and the whole pipeline — engine, planner, models — is platform-agnostic behind
the `FFmpegRunner` interface. The `android/` directory is scaffolded and the app
compiles for it; what is missing is everything around the pipeline.

What has to change:

- **`AppPaths`.** `~/speededup` means nothing on Android. Output has to go
  through the MediaStore or a user-granted tree URI, and scratch space belongs in
  the app's cache directory.
- **Import.** No drag-and-drop and no arbitrary filesystem browsing; needs the
  document picker, and `ffmpeg_kit_flutter_new` can take SAF URIs directly.
- **UI.** The menu bar, resizable window and compact always-on-top strip are all
  desktop affordances. A phone wants a bottom sheet for settings and a single
  scrolling queue.
- **Long runs.** Encoding video on a phone takes minutes and the OS will not
  leave the app in the foreground. Needs a foreground service and a progress
  notification.
- **Defaults.** `medium` preset and CRF 23 are desktop numbers. A phone needs
  faster presets and probably hardware encoding.

Worth doing after the desktop app has settled, since it will exercise the same
pipeline.

---

## 4. Desktop polish carried over from Electron

Small, self-contained, each independently useful.

- **Taskbar progress.** The original called `win.setProgressBar`. On Windows
  this needs the `ITaskbarList3` COM API — the
  [`windows_taskbar`](https://pub.dev/packages/windows_taskbar) package covers
  it, guarded by `Platform.isWindows`.
- **Completion notification.** The original raised a system notification when a
  batch finished. `local_notifier` or `flutter_local_notifications`.
- **Remember window geometry.** Size and position across restarts;
  `window_manager` already exposes what is needed.

---

## 5. Queue and workflow

Things the Electron app never had, that a batch tool wants.

- **Reorder the queue**, by drag or by buttons.
- **Per-file settings.** One noise preset for the whole batch is wrong when the
  files come from different rooms. Would mean moving `ProcessingSettings` from
  the store onto the entry, with the store holding the default.
- **Pick which audio track drives detection.** Detection reads the first track,
  which is the right default for an OBS capture but not for a file whose voice
  track happens to be second. Needs `ffprobe` to enumerate the tracks and a
  per-file choice.
- **A preview that follows the queue.** Previews are per-row; sampling the same
  stretch of every queued file in one go would suit a batch from one recording
  session.
- **Presets.** Named setting bundles — "lecture", "podcast", "screencast" —
  since the useful combinations are few and stable.
- **Retry a failed file** without re-adding it.
- **Recurse into subfolders** when importing a directory. Currently only files
  directly inside it are taken.
- **Estimated time remaining.** The encoder reports its speed; with the total
  duration known this is a straightforward projection, and it is the single most
  requested thing in a tool where a run takes twenty minutes.

---

## 6. Pipeline

- **Hardware encoding.** Measured on an AMD Radeon RX 9070, October 2026.
  The bundled FFmpeg (8, from `ffmpeg_kit_flutter_new`) has none of
  `h264_amf`, `h264_nvenc` or `h264_qsv`. It has `h264_mf`, Media Foundation,
  which reaches the GPU's encoder whatever its vendor: with `-hw_encoding 1`
  and `nv12` frames it encoded a minute of 1080p in 5.2 s against 14.0 s for
  `libx264 medium`, at the same bitrate and a slightly lower SSIM (0.964
  against 0.972). `h264_d3d12va` is in the build too, but failed in FFmpeg 8
  where FFmpeg 9 runs it. The catch is the fragments: forty sessions of 1.5 s
  took 20.2 s on `h264_mf`, 29.7 s on `libx264 medium` and 16.8 s on
  `libx264 veryfast`, because each session pays for opening the encoder. So
  the GPU pays only once there are fewer, longer sessions (next item), and it
  would still need every fragment to match for the concat, and a fallback
  where no hardware encoder exists. Meanwhile `veryfast` halved the time at
  an SSIM 0.001 lower, on synthetic footage — worth checking on real
  recordings as a cheaper default than `medium`.
- **Fewer fragments.** Each fragment is a separate FFmpeg process. A long file
  with many pauses spends real time on process startup alone. A single
  `filter_complex` with `trim`/`atrim` and `concat` could do it in one pass —
  faster and seam-free, at the cost of a much more complex filter graph and
  coarser progress reporting. The biggest available performance win.
- **Waveform preview** of the detected silences, so the settings can be judged
  visually rather than by percentage.
- **Audio-only inputs.** MP3, WAV, M4A. The pipeline assumes a video stream in
  several places (`-c:v`, the `fps` filter); audio-only would need a parallel
  argument path.

---

## 7. Testing and CI

- **Widget tests** for the settings sheet and the queue.
- **Engine tests with a fake `FFmpegRunner`.** The interface exists for this;
  what is missing is the fixture. It would cover sequencing, cancellation and
  the failure paths, which unit tests on the planner cannot reach.
- **GitHub Actions**: `flutter analyze` and `flutter test` on every push, and a
  Windows release build on tags.

---

## Not planned

- **A configurable FFmpeg path.** Removing it was the point of the rewrite.
- **Web.** FFmpeg-kit does not target it, and the app is fundamentally about
  writing files to a folder.
- **Cloud or GPU-farm processing.** Out of scope for a local desktop tool.

---

Suggestions and pull requests welcome:
<https://github.com/padvincenzo/silence-speedup/issues>
