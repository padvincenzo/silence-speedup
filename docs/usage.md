# Usage guide

How to shorten a video, and what each setting actually does.

---

## The short version

1. **Add** videos — or drag files (or a folder) onto the window.
2. Press **Start**.
3. The finished files appear next to the originals.

Before committing to a full run, the play button on a row builds a **short
sample** through the real pipeline and opens it, so you can hear the result in
roughly the time it takes to process a minute of video.

The defaults — silences at 8×, speech untouched, a noise threshold of -34 dB —
are a reasonable starting point for a recorded lecture or a screencast.

There is nothing to install and no FFmpeg path to set: FFmpeg ships inside the
app.

---

## The window

The main screen is the **queue**. The menu button in the top-left corner opens
a drawer with the other two pages, **App settings** and **About**.

| Part | What it is |
| --- | --- |
| **Add** | Import videos (`Ctrl+O`), or every supported file directly inside a folder (`Ctrl+Shift+O`). Dropping files or a folder on the window does the same. |
| Clear-queue icon | At the other end of the queue's toolbar: empties the queue. |
| **8x / 1x** button (top right) | The current silence and speech rates. Opens the encoding settings (`Ctrl+,`). |
| Compact progress icon (top right) | Shrinks the window to a slim always-on-top progress strip. |
| **Start** / **Stop** | Runs the whole queue, or interrupts it (`Ctrl+D`). |
| Bottom strip | Position, encoder speed and percentage for the file being worked on. Its terminal icon shows or hides the log. |

On a wide window the encoding settings are docked to the right of the queue,
and the button in the panel's title hides them; whether the panel is shown is
remembered. On a narrow window they open as a side sheet instead, which closes
on Escape, on its own button, or by clicking beside it.

Each queued file shows its status and, when finished, how much of it was
silence. The actions on a row:

- **Generate a short preview sample** (play) — encodes a short stretch of the
  video through the full pipeline and opens it. This is the one that answers
  "does this *sound* right".
- **Measure the silences without exporting** (waveform) — runs only the
  detection pass and reports the percentage found. Seconds rather than minutes.
- **Show the detected silences** (timeline) — appears once a file has been
  analysed or processed. See [The detected silences](#the-detected-silences).
- **Show the exported file** (folder) — opens the output folder of a finished
  file.
- **Remove this video from the list** (bin).

Supported inputs: AVI, FLV, MKV, MOV, MP4, WebM, WMV.

> The queue is keyed by file name, so two files with the same name cannot be
> queued together even from different folders — they would collide in the export
> folder.

---

## Encoding settings

The settings that shape a video are grouped in the encoding panel: **Speed**,
**Audio**, **Silence detection**, **Export** and **Preview**. Every setting
explains itself in place; this is the longer version.

A closed group shows only what differs from the default, so you can tell at a
glance what you have changed. Settings are remembered between sessions, and
**Reset**, at the bottom of the panel, puts all of them back to their defaults.
They cannot be changed while a run is in progress.

### Speed

**Silence speed** — how fast the quiet stretches play, from 0.5x to 20x. `8x`
keeps the pause audible but brief; **Remove** cuts them out completely.

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

**Background noise** — the level, in decibels, below which a sound counts as
silence, from -60 dB to -10 dB. The labels under the slider are what the
numbers mean: **Low** (-54 dB) for a quiet room with the microphone close to
the speaker, **Mid** (-34 dB, the default) for a normal room, **High** (-20 dB)
for a noisy room or a distant microphone.

The right value depends on the recording, so the app can measure it. Press
**Measure** under the slider: it reads the background hiss and the voice level
of the first video in the queue — *hiss at -64 dB, voice at -22 dB* — and
offers the value halfway between them, **Suggested: -43 dB**, which a click
applies. If the hiss is nearly as loud as the voice, it says so instead: no
threshold separates them cleanly.

If pauses are being missed, raise the threshold. If words are being clipped as
silence, lower it.

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

**Export to** — where a finished video is written. **Beside the source**
(default) keeps each one in its own folder; **A folder I pick** sends them all
to one folder, which is remembered.

Existing files are never overwritten: a name collision gets ` (1)` appended.
That guarantee matters with the default — keeping the source container would
otherwise mean writing over the original. Preview samples are named
`<video> (preview).<ext>`, so they never compete with the real output.

Leave the rest alone unless you have a reason.

**Video format** — container for the output. **Keep** reuses the source's.

**CRF** — quality. Lower is better and larger; `23` (default) is visually
transparent for most screen and talking-head content. Below ~18 the files get
big fast; above ~28 the artefacts start to show.

**FPS** — the frame rate every fragment is normalised to. This is not cosmetic:
it is what allows the pieces to be joined without re-encoding. If your source is
variable-frame-rate, or you see stutter, set it to match the source.

**Preset** — how hard the encoder works. Slower presets give smaller files at
the same quality. `Medium` (default) is a fair trade; `Very fast` roughly halves
the encode time at some size cost.

**Tune** — a hint to x264 about the kind of content. `Still image` suits slides,
`Film` suits camera footage. **None** (default) is fine.

### Preview

**Preview length** — how much of the video a preview sample covers: 30, 60
(default) or 120 seconds. The sample is taken from a third of the way in, where
a recording is most representative — the opening is usually titles, or someone
settling down before they start talking.

---

## The detected silences

The timeline button on a row opens what the detection found for that file:

- a **timeline** of the whole video with every silence marked. Zoom with the
  buttons or with `Ctrl` and the mouse wheel, down to two seconds across the
  window; the wheel alone moves the view. The strip underneath shows where you
  are: drag it to move, or click elsewhere on it to jump there;
- the **figures**: total silence, its share of the source, the estimated length
  of the result with the current settings, and the time saved;
- the **list of silences**. Pressing one shows it on the timeline.

The ranges are the ones found when the file was analysed. If the threshold, the
minimum duration or the margin have changed since, the page says so and offers
to **Detect again**, rather than redrawing old ranges against new settings.

---

## App settings

From the drawer. These are about the application, not about a video.

**Theme** — follow the system, or pin light or dark.

**Language** — follows the system language and falls back to English; pick
Deutsch, English, Español, Français, Italiano, 日本語 or Português to override
it.

**Working directory** — where the intermediate fragments go while a run is in
progress, by default inside the system temp folder. The page shows how much
space they use, can **Clear** them, and can **Change folder**.

Fragments are deleted after a file completes successfully, and **kept when
something fails** — they are usually the only clue as to which part of the file
went wrong, and the log says where they are. Moving the working directory is
worth it if the drive holding your temp folder is short of room: the fragments
of a long video can add up to several gigabytes while a run is in progress.

---

## While it runs

The bottom strip shows the position reached in the current file, the encoder's
speed relative to real time, and the percentage done. The log carries the
detail: how much of each file was detected as silence, any FFmpeg warnings, and
where fragments were left if something failed.

For long batches, the compact progress button shrinks the window to a thin
always-on-top strip that stays out of the way. It shows progress and keeps a
Stop button.

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
interpreted. Try a different noise threshold.

**Nothing was detected.** No silence matched your settings; the file is copied
through unchanged. Raise the noise threshold or lower the minimum duration.

**The output is choppy.** The minimum duration is too low, or the margin too
small — short gaps are being cut. Raise both.

**Words are clipped.** Raise the silence margin, or lower the noise threshold.

**Audio drifts out of sync.** Set FPS explicitly to match the source; a
variable-frame-rate input is the usual cause.

**An audio track is missing from the output.** Turn on **Keep all audio tracks**
in the Audio group. Without it only the first track is exported.

**The preview sounds right but the full run does not.** The sample covers one
stretch of the video. If the room noise changes partway through — a different
speaker, a window opened — one threshold will not fit the whole file.

The log is the first place to look, and the fragments left behind after a
failure are the second.

---

## Keyboard

| Shortcut | Action |
| --- | --- |
| `Ctrl+O` | Add video(s) |
| `Ctrl+Shift+O` | Add folder |
| `Ctrl+,` | Show or hide the encoding settings |
| `Ctrl+D` | Stop |
| `Ctrl+Q` | Quit |
