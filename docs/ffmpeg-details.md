# FFmpeg details

Exactly what the app asks FFmpeg to do, and why each flag is there. Everything
below is built in
[lib/services/fragment_planner.dart](../lib/services/fragment_planner.dart) and
asserted in [test/fragment_planner_test.dart](../test/fragment_planner_test.dart)
and [test/preview_and_audio_test.dart](../test/preview_and_audio_test.dart).

---

## Where FFmpeg comes from

FFmpeg is provided by the [`ffmpeg_kit_flutter_new`](https://pub.dev/packages/ffmpeg_kit_flutter_new)
plugin, in its **full-GPL** variant. There is no binary in this repository and
no path for the user to configure.

Full-GPL matters: `libx264` is GPL-licensed and is only present in that variant.
Every fragment is encoded with `libx264`, so a lighter build of the plugin would
break the app rather than merely limit it.

On Windows the prebuilt libraries are downloaded at build time and end up beside
the executable (`avcodec-*.dll`, `libx264-*.dll`, and so on).

---

## Step 1 — Detect the silences

```
ffmpeg -hide_banner -dn -vn \
       -ss 0 -i <input> \
       -map 0:a:0 \
       -af silencedetect=n=0.02:d=0.5 \
       -f null -
```

| Flag | Why |
| --- | --- |
| `-dn -vn` | Discard data and video streams. Only the audio is examined, which makes this pass much faster than a decode of the whole file. |
| `-map 0:a:0` | The **first** audio track only. In a multi-track recording that is the voice; the other tracks — game audio, system sound — must not decide where the pauses are. |
| `-f null -` | Decode and throw the result away; the useful output is on the log, not in a file. |
| `n=` | Noise floor as a **linear amplitude ratio** (`0.002` / `0.02` / `0.1` for the Low / Mid / High presets), not decibels. `silencedetect` accepts either form. |
| `d=` | Minimum silence duration — but see below, it is *not* the value from the slider. |

The pass prints boundary lines that the app parses:

```
[silencedetect @ 000001] silence_start: 12.3456
[silencedetect @ 000001] silence_end: 18.9 | silence_duration: 6.5544
```

### Why `d=` is wider than the slider says

The user asks for two things that pull against each other: a minimum silence
duration, and a margin of audio kept on each side so words are not clipped.
Applying the margin *after* detection would shrink each range by twice the
margin, and a range detected at exactly the minimum would end up shorter than
the minimum the user asked for.

So the detection window is widened up front:

```
d = silenceMinDuration + 2 × silenceMargin
```

Then each detected range is trimmed back by the margin at both ends, and what
survives is at least `silenceMinDuration` long. The Settings sheet shows the
resulting filter string, so the widening is visible rather than surprising.

### Boundary pairing

`starts` and `ends` must pair up one-to-one. Two cases are handled:

- **A file that fades out into silence** can produce a final `silence_start`
  with no matching `silence_end`. The end of the media closes it.
- **Any other mismatch** is reported as a data error and the file is skipped;
  guessing at that point would cut the wrong parts.

Ranges that the margin has eaten entirely, and ranges that would overlap their
predecessor, are dropped.

### Sampling part of a file

A preview examines one stretch rather than the whole file, by bounding what
FFmpeg reads with two input options — `-ss 280 -t 60` before `-i`.

Because both are *input* options, FFmpeg seeks and then stops, rather than
decoding the whole file and discarding the rest. A preview therefore costs about
what processing those seconds costs, and nothing has to be trimmed out first.

`silencedetect` reports positions relative to its own seek, so `buildRanges`
adds the window's start back and clamps to the window. From there on everything
works in absolute source seconds, exactly as it does for a full run.

---

## Step 2 — Encode each stretch at its own rate

The timeline is walked into alternating fragments — speech, silence, speech,
silence — covering the file end to end with no gaps and no overlaps. When the
silence speed is **Remove**, the silent fragments are simply never emitted.

Each fragment is encoded separately:

```
ffmpeg -hide_banner -y -loglevel warning -stats -dn \
       -ss 10.500000 -to 19.500000 -i <input> \
       -map 0:v:0? -map 0:a:0? \
       -map_metadata -1 -map_chapters -1 \
       -segment_time_metadata 0 -max_muxing_queue_size 99999 \
       -c:a aac -c:v libx264 -preset medium -crf 23 \
       -vsync cfr -fflags +genpts \
       -vf "setpts=0.125*PTS,fps=fps=30:round=near" \
       -af "atempo=2,atempo=2,atempo=2" \
       <tmp>/f_000001.mp4
```

| Flag | Why |
| --- | --- |
| `-ss` / `-to` **before** `-i` | As *input* options these are absolute positions in the source, which is what the fragment plan produces. Placed after `-i` they would mean something different. |
| `-map 0:v:0? -map 0:a:0?` | Explicit stream selection. Without it FFmpeg's default selection keeps one audio track and silently drops the others. With **Keep all audio tracks** on, the audio map becomes `0:a?`. The trailing `?` makes a missing stream non-fatal, so a file with no video still encodes. |
| `-map_metadata -1`, `-map_chapters -1` | Fragments carry no metadata or chapters; keeping them would confuse the join. |
| `-fflags +genpts` | Generate fresh timestamps, so each fragment starts at zero. |
| `-vsync cfr` + `fps` filter | Normalise every fragment to one constant frame rate. This is what allows step 3 to copy streams instead of re-encoding. |
| `-max_muxing_queue_size 99999` | Avoids a muxer failure on sources with widely separated audio and video packets. |

### `setpts` and `atempo`

`setpts=0.125*PTS` compresses the video timeline 8×. `atempo` does the audio,
but **one `atempo` caps at 2×**, so higher rates chain several
(`atempo=2,atempo=2,atempo=2` for 8×). Odd multipliers are made up with a
trailing `atempo=1.25`. The chains are precomputed in
[lib/models/options.dart](../lib/models/options.dart).

### `fps=fps=30:round=near` is not a typo

The `fps` filter has an option that is itself named `fps`. The catalogue stores
the filter's *arguments* (`fps=30:round=near`), and the composed filter is
therefore `fps=fps=30:round=near`. Valid, if odd to read.

### Several audio tracks at once

With **Keep all audio tracks** on, the fragment maps `0:a?` — every audio track
— and the tempo filter still reaches all of them, because `-af` is shorthand for
`-filter:a`, a *per-stream* option: each mapped audio stream gets its own copy of
the graph and stays in step with the video.

`-c:a aac` likewise applies to every mapped audio stream, so all of them reach
the concat step in the same format.

### Muting a silence

When **Mute silences** is on, `volume=0` is **appended** to the tempo chain:

```
-af "atempo=2,atempo=2,atempo=2,volume=0"
```

It replaces nothing. Dropping `atempo` would leave the audio at its original
length while the video was compressed 8×, and since the fragments are joined
without re-encoding, that mismatch would desync everything after it.

> The Electron app used `-af volume=enable=0` *instead of* the tempo filter.
> `enable=0` disables the filter outright, so it did not mute at all, and losing
> `atempo` desynced the result. See [porting-notes.md](porting-notes.md).

---

## Step 3 — Join the fragments

```
ffmpeg -hide_banner -y -loglevel warning -stats \
       -segment_time_metadata 0 -vsync cfr \
       -f concat -safe 0 -i <tmp>/list.txt \
       -map 0 \
       -c:a copy -c:v copy \
       <export>/<name>.mp4
```

`-map 0` takes **every** stream of the fragments. Default stream selection would
pick one video and one audio track, which would drop a second audio track at the
very last step after carrying it correctly all the way through.

No re-encoding — the streams are copied, which is why this step is fast
regardless of how long the video is. The cost is the invariant described in
[architecture.md](architecture.md): every fragment must share codecs, container
and frame rate.

`list.txt` is one line per fragment:

```
file 'C:/Users/vin/speededup/tmp/run_1757437.../f_000000.mp4'
file 'C:/Users/vin/speededup/tmp/run_1757437.../f_000001.mp4'
```

Two escaping rules, both easy to get wrong on Windows:

- **Backslashes become forward slashes.** The concat demuxer reads a backslash
  as an escape character, so `C:\tmp\f_0.mp4` would be mangled.
- **A single quote in a path** is written as `'\''`, the escape the format
  requires.

`-safe 0` allows absolute paths in the list.

---

## Temporary files

Each entry works in its own directory under the configured working directory,
which defaults to a folder inside the system temp directory:

```
<working directory>/run_<microseconds>/
    f_000000.mp4
    f_000001.mp4
    ...
    list.txt
```

The scratch space is deliberately **not** under the export folder: that folder
can be set to follow each source file, so there is no single place under it to
put fragments — and encoder scratch has no business appearing in a video folder.

Per-run isolation means an interrupted run cannot leave fragments behind that a
later run would pick up. The directory is **deleted after success** and **kept
after a failure**, with its path written to the log — the fragments are usually
the only way to tell which part of a file FFmpeg choked on.

Preferences shows how much space the working directory is using, offers to empty
it, and can move it — useful when the temp drive is short of room.

> The Electron app reused one shared `tmp` directory under the export folder,
> and never cleaned it up.

---

## Output naming

The output goes to the export directory — by default the folder the source came
from — named after the source, with the chosen container's extension. A preview
gets a ` (preview)` suffix before the extension, so it never competes with the
real output.

If that name is already taken, or would be the source file itself, a counter is
appended: `lecture (1).mp4`.

> The Electron app passed `-y` and overwrote. With **Keep** as the format and an
> export directory that happened to be the source folder, it destroyed the
> original.

---

## Reference

- [`silencedetect`](https://ffmpeg.org/ffmpeg-filters.html#silencedetect)
- [`setpts`](https://ffmpeg.org/ffmpeg-filters.html#setpts-1) ·
  [`atempo`](https://ffmpeg.org/ffmpeg-filters.html#atempo) ·
  [`fps`](https://ffmpeg.org/ffmpeg-filters.html#fps-1) ·
  [`volume`](https://ffmpeg.org/ffmpeg-filters.html#volume)
- [concat demuxer](https://ffmpeg.org/ffmpeg-formats.html#concat)
- [H.264 encoding guide](https://trac.ffmpeg.org/wiki/Encode/H.264)
