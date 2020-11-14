# Silence Speedup
Speed-up your videos speeding-up (or removing) silences, using FFmpeg.

<img src="screenshots/Screen%2300%20Homescreen.png" alt="Homescreen" width="410"/>

*Read this in other languages: [English](README.md), [Italian](README.it.md).*

## Table of Contents
  - [How it works](#how-it-works)
    - [Note](#note)
  - [Requirements](#requirements)
  - [Credits](#credits)
  - [Screenshots](#screenshots)

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

## Screenshots

1.  Some videos added
<img src="screenshots/Screen%2301%20Video%20added.png" alt="Video added" width="410"/>

2.  Video list zone
<img src="screenshots/Screen%2302%20Video%20list.png" alt="Video list" width="410"/>

3.  Add videos (one by one, by folder or drag&drop in video list zone)
<img src="screenshots/Screen%2303%20Add%20videos.png" alt="Add videos" width="410"/>

4.  Options zone
<img src="screenshots/Screen%2304%20Video%20options.png" alt="Video options" width="410"/>

5.  Start
<img src="screenshots/Screen%2305%20Start%20the%20program.png" alt="Start" width="410"/>

6.  "Shell"
<img src="screenshots/Screen%2306%20Shell.png" alt="Shell" width="410"/>

7.  Progress bar
<img src="screenshots/Screen%2307%20Progress%20bar.png" alt="Progress bar" width="410"/>

8.  Show minimal interface
<img src="screenshots/Screen%2308%20Show%20minimal%20interface.png" alt="Show minimal interface" width="410"/>

9.  Minimal interface
<img src="screenshots/Screen%2309%20Minimal%20interface.png" alt="Minimal interface" width="410"/>

10. Completed videos
<img src="screenshots/Screen%2310%20Completed%20videos.png" alt="Completed videos" width="410"/>

11. Current video
<img src="screenshots/Screen%2311%20Current%20video.png" alt="Current video" width="410"/>

12. Show default interface
<img src="screenshots/Screen%2312%20Show%20default%20interface.png" alt="Show default interface" width="410"/>

