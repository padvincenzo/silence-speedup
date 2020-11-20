# Silence Speedup
Speed-up your videos speeding-up (or removing) silences, using FFmpeg.

![Homescreen](screenshots/Homescreen.png)

*Read this in other languages: [English](README.md), [Italian](README.it.md).*

## Table of Contents
  - [Installation](#installation)
    - [Requirements](#requirements)
  - [How it works](#how-it-works)
    - [Note](#note)
  - [Credits](#credits)

## Installation
This program is packaged with [``electron-packager``](https://electron.github.io/electron-packager/master/), and it should run out-of-the-box. If you want to run this program by yourself from the source code, then:

```
$ git clone https://github.com/padvincenzo/silence-speedup
$ cd silence-speedup
$ npm install
$ npm start
```

### Requirements
This program require [ffmpeg](https://ffmpeg.org/download.html) to process your videos. If you have it already installed, then open the program and just change the configuration by clicking on the configuration button.

If you wish to run this program from the source files then you also need to install [NodeJS](https://nodejs.org/en/).

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

## Credits
This software uses libraries from the FFmpeg project, which I do not own, under the LGPLv2.1.
