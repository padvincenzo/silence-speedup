# 📖 Usage Guide – Silence Speedup

This guide explains how to use Silence Speedup to shorten videos or
audio by skipping or accelerating silent parts.

---

## 🧩 Interface Overview

- **Import**: Drag-and-drop your video/audio file or use `File → Open`.
- **Settings**: Click the gear icon or `File → Settings` to adjust how silence is detected and handled.
- **Start**: Once you're ready, press **Start** to begin processing.

---

## 🎚 Silence Detection Settings

These settings affect how FFmpeg identifies silence in your media:

### 🔉 Noise Level Preset

Choose the ambient noise level for your recording:
- **Low**: Very quiet room, close microphone
- **Medium**: Normal room with some background noise
- **High**: Noisy room or distant microphone

This changes the FFmpeg `silencedetect` threshold.

### 🕐 Minimum Silence Duration

Defines how long a pause must be to count as “silence” (in seconds).
Shorter values capture more pauses, longer values filter out brief hesitations.

### 🛑 Keep Initial Seconds of Silence

Allows keeping a few seconds at the start/end of detected silence to avoid
cutting off spoken words abruptly. Helpful for natural-sounding edits.

---

## ⚙️ Filter Settings

These affect playback speed of each segment:

- **Speech Speed**: Playback rate for non-silent sections (default: 1.0×)
- **Silence Speed**: Speed for silent parts (e.g., 4.0× or `skip`)
- **Video-only Mode**: Optionally keep video during silence but mute audio

---

## 🎬 Export Settings

Choose how the output video is encoded:

- **Format**: Defaults to same as input (`.mp4`, `.mov`, etc.)
- **FPS (Frames per second)**: Useful if source has variable frame rate
- **CFR**: Constant Frame Rate option
- **H.264 Preset**: Choose `ultrafast`, `medium`, `slow`, etc.
- **Audio Codec**: Uses `aac` by default

> Temporary and output files are stored in `~/speededup/` by default. You can change this in settings.

---

## 🧪 Previewing Results

Once processing is complete, a new video will be created in the output folder.
Play it to verify that speech is intact and transitions feel natural.

If needed, tweak silence thresholds and re-run the process.
