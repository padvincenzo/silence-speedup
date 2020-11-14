# Silence Speedup
Speed-up your videos speeding-up (or removing) silences, using FFmpeg.

![Homescreen](screenshots/Homescreen.png =250x250)

*Read this in other languages: [English](README.md), [Italian](README.it.md).*

## Table of Contents
  - [How it works](#how-it-works)
    - [Front-end](#front-end)
      - [Default interface](#default-interface)
      - [Minimal interface](#minimal-interface)
    - [Back-end](#back-end)
    - [Note](#note)
  - [Requirements](#requirements)
  - [Credits](#credits)

## How it works

### Front-end

#### Default interface
![Default interface](screenshots/Default%20interface.png)

#### Minimal interface
![Minimal interface](screenshots/Minimal%20interface.png)

### Back-end
For each video, this program will:

1.  Run ffmpeg with ``silencedetect`` filter, in order to get the list of silences' start/end timestamps.

```
<ffmpeg bin> -hide_banner -vn \
  -ss 0.00 -i <Input file> \
  -af silencedetect=n=<threshold>:d=<duration> \
  -f null -
```

2.  Using that list, split the original video in a tmp folder, applying a speed filter, if any.

```
<ffmpeg bin> -hide_banner -loglevel warning -stats \
  -ss <Start time> -to <End time> -i <Input file> \
  -filter_complex "[0:v]<setpts filter>[v];[0:a]<atempo filter>[a]" \
  -map [v] -map [a] <Output fragment>
```

3.  Concatenate all the fragments generated before.

```
<ffmpeg bin> -hide_banner -loglevel warning -stats \
  -f concat -safe 0 \
  -i <Fragment list file> \
  -c copy \
  -map v -map a <Output file> -y
```

### Note
At the end of execution, the program does not automatically clean the tmp folder.

## Requirements
In ``win32`` and ``darwin`` versions ``ffmpeg`` executable is included in the package; on ``linux`` you need to install it manually.

## Credits
This software uses libraries from the FFmpeg project, which I do not own, under the LGPLv2.1.
