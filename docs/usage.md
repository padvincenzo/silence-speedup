# Usage guide

How to shorten a video, and what each setting actually does.

---

## The short version

1. **Add video(s)** — or drag files (or a folder) onto the window.
2. Press **Start**.
3. The finished files appear next to the originals.

Before committing to a full run, the play button on a row builds a **short
sample** through the real pipeline and opens it, so you can hear the result in
roughly the time it takes to process a minute of video.

The defaults — silences at 8×, speech untouched, medium noise floor — are a
reasonable starting point for a recorded lecture or a screencast.

There is nothing to install and no FFmpeg path to set: FFmpeg ships inside the
app.

---

## The window

The app has three screens, reached from the menu button in the top-left corner:
**Queue**, **Settings** and **About**.

On the queue:

| Part | What it is |
| --- | --- |
| **Add video(s)** / **Add folder** | Import files, or every supported file directly inside a folder. |
| **8x / 1x** chip | Current silence and speech rates. Tap it to open Settings. |
| **Export to** row | Where results go. Editable in place. |
| **Start** / **Stop** button | Runs the whole queue, or interrupts it. |
| Terminal icon (top right) | Shows or hides the log. |
| Picture-in-picture icon | Shrinks the window to a slim always-on-top progress strip. |
| Playlist icon | Empties the queue. |
| Bottom strip | Position, encoder speed and percentage for the file being worked on. |

Each queued file shows its status and, when finished, how much of it was
silence. Three per-row actions:

- **Generate a short preview sample** — encodes a short stretch of the video
  through the full pipeline and opens it. This is the one that answers "does
  this *sound* right".
- **Measure the silences without exporting** — runs only the detection pass and
  reports the percentage found. Seconds rather than minutes; use it to check
  whether the thresholds are sane.
- **Show the exported file** — opens the output folder.

Supported inputs: AVI, FLV, MKV, MOV, MP4, WebM, WMV.

> The queue is keyed by file name, so two files with the same name cannot be
> queued together even from different folders — they would collide in the export
> folder.

---

## Settings

Reached from the menu button, or by tapping the **8x / 1x** chip on the queue.
Every setting says what it does on the page itself; this is the longer version.

### Speed

**Silence speed** — how fast the quiet stretches play. `8x` keeps the pause
audible but brief; **Remove** cuts them out completely.

> Removing is not always better. A pause cut to nothing can make speech feel
> clipped and unnatural, especially between sentences. `8x` or `16x` usually
> sounds smoother while saving nearly as much time.

**Speech speed** — how fast the parts where someone is talking play. Leave at
`1x` unless you want the whole thing faster; `1.25x` is generally still
comfortable to listen to. This one cannot be set to Remove.

### Audio

**Keep all audio tracks** — carries every audio track of the source into the
output instead of only the first. Silences are still detected from the first
track alone.

> This is what a multi-track recording needs. If you record your voice to track
> 1 and game or system audio to track 2 — OBS does this by default — the video
> is cut according to the pauses in your voice, and every track comes out the
> other side. With the option off, only the first track survives.

**Mute silences** — silences the audio of the quiet parts instead of letting
sped-up room hiss through. Useful at high silence rates, where the noise floor
turns into a chirp. Unavailable when silences are removed, since there is
nothing left to mute.

**Audio rate** — resample the audio. **Keep** leaves it exactly as it is, which
is almost always right.

### Silence detection

**Background noise** — how loud the room is allowed to be before it counts as
sound.

| Preset | Use it for |
| --- | --- |
| **Low** | Quiet room, microphone close to the speaker |
| **Mid** | A normal room with some background noise (default) |
| **High** | Noisy room, distant or built-in microphone |

If pauses are being missed, raise it. If words are being clipped as silence,
lower it.

**Silence min duration** — how long a pause must last to count. `0.30 s`
(default) catches ordinary pauses between sentences. Raise it to leave short
hesitations alone; lower it to squeeze out every gap, at the cost of a choppier
result.

**Silence margin** — audio kept on each side of every silence, so words are not
cut off at the edges. `0.10 s` (default) is enough for most speech. Raise it if
the result sounds clipped at the start or end of sentences.

> These two interact: the app searches for silences of
> `min duration + 2 x margin`, then trims each one back by the margin, so what
> survives is still at least the minimum you asked for. The group shows the
> resulting detection filter, if you want to see it.

### Export

Leave these alone unless you have a reason.

**Video format** — container for the output. **Keep** reuses the source's.

**CRF** — quality. Lower is better and larger; `23` (default) is visually
transparent for most screen and talking-head content. Below ~18 the files get
big fast; above ~28 the artefacts start to show.

**FPS** — the frame rate every fragment is normalised to. This is not cosmetic:
it is what allows the pieces to be joined without re-encoding. If your source is
variable-frame-rate, or you see stutter, set it to match the source.

**Preset** — how hard the encoder works. Slower presets give smaller files at
the same quality. `medium` (default) is a fair trade; `veryfast` roughly halves
the encode time at some size cost.

**Tune** — a hint to x264 about the kind of content. `Still image` suits slides,
`Film` suits camera footage. **None** (default) is fine.

### Preview

**Preview length** — how much of the video a preview sample covers: 30, 60
(default) or 120 seconds. The sample is taken from a third of the way in, where
a recording is most representative — the opening is usually titles, or someone
settling down before they start talking.

### Application

**Theme** — follow the system, or pin light or dark.

**Language** — follows the system language and falls back to English; pin
English or Italiano to override it.

**Working directory** — where the intermediate fragments go while a run is in
progress. See below.

Also here: **Reset processing settings**, which puts every speed, detection and
export setting back to its default and leaves the application ones alone.

---

## Where the results go

The **Export to** row sits on the main window, right under the toolbar, because
this is the setting that changes most often.

- **Next to the source video** (default) — each result is written into the same
  folder as the file it came from.
- Untick it and the folder becomes editable: type a path, or pick one with the
  browse button. It is remembered, so switching back and forth costs nothing.

A typed path is applied when you press Enter or click away, and the folder is
created if it does not exist yet.

Existing files are never overwritten: a name collision gets ` (1)` appended.
That guarantee matters with the default setting — keeping the source container
would otherwise mean writing over the original.

Preview samples are named `<video> (preview).<ext>`, so they never compete with
the real output.

## Temporary files

While processing, the app writes intermediate fragments to a working directory,
by default inside the system temp folder. They are deleted after a file
completes successfully, and **kept when something fails** — they are usually the
only clue as to which part of the file went wrong, and the log says where they
are.

**Settings → Application** shows how much space they use, can empty them, and
can move the working directory. Worth moving if the drive holding your temp folder
is short of room: the fragments of a long video can add up to several gigabytes
while a run is in progress.

---

## While it runs

The bottom strip shows the position reached in the current file, the encoder's
speed relative to real time, and the percentage done. The log (terminal button)
carries the detail: how much of each file was detected as silence, any FFmpeg
warnings, and where fragments were left if something failed.

For long batches, the minimise button shrinks the window to a thin always-on-top
strip that stays out of the way. It shows progress and keeps a Stop button.

**Stop** interrupts after the current fragment. The file being worked on is
marked interrupted and left unfinished; earlier files in the queue keep their
completed outputs.

Expect a full run to take a while: every fragment is re-encoded, so processing
is slower than real time on most machines. The final join is fast, because it
copies rather than re-encodes.

---

## If something goes wrong

**A file shows an error as soon as it is added.** Its duration could not be read
— the file is corrupt, or not really the format its extension claims.

**"Analysis failed."** The detection pass could not run. Check the log; a file
with no audio track at all will fail here.

**"Silence boundaries do not pair up."** The detection output could not be
interpreted. Try a different noise preset.

**Nothing was detected.** No silence matched your settings; the file is copied
through unchanged. Raise the noise preset or lower the minimum duration.

**The output is choppy.** The minimum duration is too low, or the margin too
small — short gaps are being cut. Raise both.

**Words are clipped.** Raise the silence margin, or lower the noise preset.

**Audio drifts out of sync.** Set FPS explicitly to match the source; a
variable-frame-rate input is the usual cause.

**An audio track is missing from the output.** Turn on **Keep all audio tracks**
in Settings. Without it only the first track is exported.

**The preview sounds right but the full run does not.** The sample covers one
stretch of the video. If the room noise changes partway through — a different
speaker, a window opened — one noise preset will not fit the whole file.

The log is the first place to look, and the fragments left behind after a
failure are the second.

---

## Keyboard

| Shortcut | Action |
| --- | --- |
| `Ctrl+O` | Add video(s) |
| `Ctrl+Shift+O` | Add folder |
| `Ctrl+D` | Stop |
| `Ctrl+Q` | Quit |

---

Theme (light / dark / system) and language (System / English / Italiano) are in
**Settings**, under *Application* — along with the working directory.
