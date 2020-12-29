# Silence Speedup
Speed-up your videos speeding-up (or removing) silences, using FFmpeg.

![Homescreen](assets/screenshots/homescreen.png)

*Read this in other languages: [English](README.md), [Italian](README.it.md).*

## Table of Contents
  - [Getting started](#getting-started)
    - [Download](#download)
      - [Standalone](#standalone)
      - [Without FFmpeg binaries](#without-ffmpeg-binaries)
    - [How to use](#how-to-use)
    - [Program settings](#program-settings)
      - [Silence detect](#silence-detect)
      - [Filter](#filter)
      - [Export](#export)
    - [Requirements](#requirements)
  - [Compiling](#compiling)
  - [How it works](#how-it-works)
    - [Note](#note)
  - [Contributing](#contributing)
  - [Credits](#credits)

## Getting started
This program, built with Electron, makes use of FFmpeg in order to speed up (or skip) parts of the video that are with no sound.

It is really helpful for video lessons, where the professor takes long time for writing something on the board, makes lots of pauses, or just speaks slowly. With this program you can skip this boring parts and save time.

Of course this program is not perfect, and you might have to practice a bit with it.

### Download

#### Standalone
(FFmpeg binaries inside)

* [Windows](https://github.com/padvincenzo/silence-speedup/releases/download/v1.2.0/Silence-SpeedUp-v1.2.0-win32-ia32-standalone.zip) (97.1 MB)
* [MacOS](https://github.com/padvincenzo/silence-speedup/releases/download/v1.2.0/Silence-SpeedUp-v1.2.0-darwin-x64-standalone.zip) (245 MB)
* [Linux](https://github.com/padvincenzo/silence-speedup/releases/download/v1.2.0/Silence-SpeedUp-v1.2.0-linux-x64-standalone.zip) (101 MB)

#### Without FFmpeg binaries
* [Windows](https://github.com/padvincenzo/silence-speedup/releases/download/v1.2.0/Silence-SpeedUp-v1.2.0-win32-ia32.zip) (72 MB)
* [MacOS](https://github.com/padvincenzo/silence-speedup/releases/download/v1.2.0/Silence-SpeedUp-v1.2.0-darwin-x64.zip) (223 MB)
* [Linux](https://github.com/padvincenzo/silence-speedup/releases/download/v1.2.0/Silence-SpeedUp-v1.2.0-linux-x64.zip) (74.1 MB)

### How to use
Import your videos, choose the [program settings](#program-settings) and press ``Start``. The app shows you the progress status, which consists of 3 steps: ``Detecting silences``, ``Exporting`` and ``Concatenating``.

### Program settings
Not all videos are with the same audio volume, and you may want to choose which silences should be treaten as that. So, here we have the configurable parts.

#### Silence detect
These settings change the way FFmpeg detect silences. You can set:

* The background noise of the video (`Low` for a silent room with a microphone, `Mid` for the average noisy room, `High` for a noisy room). Note: if your are new, try a video with defaults settings and see the result.

* How many seconds the smallest silence lasts (this value prevent brief pauses to be treaten as silences).

* How many seconds of silences should not be treaten as silences (explaination: without a minimum time of margin, spoken words might merge and the result would be an incomprehensible speech).

#### Filter
With these settings you can change the speed of spoken/silence parts of the video, and also set silence parts to be video-only.

#### Export
Choose the format (extension) of your video. Default is set to keep the same extension. In this way, I noticed that some formats (e.g. `avi`) loose video quality during the process.

Note: the default path of the videos (as well as temporary files) is set to `<your home path>/speededup/`. If you want to change it, press the settings button or go to `File -> Settings`.

### Requirements
This app comes in 2 versions: the one called standalone has FFmpeg binaries inside and it does not require anything to run. The other version is without FFmpeg: you have to download and configure it.

## Compiling
This program does not need to be installed to run, as I packaged it with [``electron-packager``](https://electron.github.io/electron-packager/master/). But, if you want to compile and run this program by yourself from the source code, then:

```
$ git clone https://github.com/padvincenzo/silence-speedup
$ cd silence-speedup
$ npm install
$ npm start
```

If you wish to run this program from source files then you also need to install [NodeJS](https://nodejs.org/en/).

## How it works
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

## Contributing
Anyone can contribute to this project, in many ways:
* Translating this project in other languages;
* Finding and report/fix bugs;
* Suggesting new ideas;
* Implementing new functionalities.

For any doubt or perplexity we can [discuss here](https://github.com/padvincenzo/silence-speedup/discussions)

## Credits
This software uses binaries of the FFmpeg project, which I do not own, under the GPLv3.
