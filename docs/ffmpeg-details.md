# 🧠 FFmpeg Details – Silence Speedup

This document describes how Silence Speedup uses FFmpeg under the hood to process videos.

---

## 🎙 Step 1 – Detect Silence

Silence is detected using FFmpeg's `silencedetect` audio filter:

```bash
ffmpeg -hide_banner -vn \
  -ss 0.00 -i input.mp4 \
  -af silencedetect=n=-30dB:d=0.3 \
  -f null -
```

* `n=` sets the noise threshold (e.g. `-30dB`)
* `d=` sets minimum silence duration (e.g. `0.3` seconds)

The output is parsed to extract timestamps for each silent section.

## ✂️ Step 2 – Split and Process Segments
Each segment (silent or spoken) is processed using the `setpts` (video) and `atempo` (audio) filters:

```bash
ffmpeg -hide_banner -loglevel warning -stats \
  -ss START -to END -i input.mp4 \
  -filter_complex "[0:v]setpts=PTS/1.0[v];[0:a]atempo=1.0[a]" \
  -map [v] -map [a] output_segment.mp4
```

* `setpts=PTS/1.0`: adjusts video speed
* `atempo=1.0`: adjusts audio speed (up to 2.0 per filter; can be chained for higher speeds)

## 📎 Step 3 – Concatenate Segments
Processed segments are merged back into a single file using FFmpeg's concat demuxer:

```bash
ffmpeg -hide_banner -loglevel warning -stats \
  -f concat -safe 0 \
  -i segment_list.txt \
  -c copy \
  output_final.mp4
```

> `segment_list.txt` contains a list of intermediate output files.

## 🧹 Temporary Files
Intermediate fragments and logs are stored in a temporary folder (default: `~/speededup/tmp/`).
These are *not* auto-deleted.

Consider cleaning them up periodically.

## 🔍 Useful Links
* [FFmpeg silencedetect docs]()
* [H.264 Encoding Guide]()
* [FFmpeg concat guide]()
