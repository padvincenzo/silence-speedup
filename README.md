# Silence Speedup
Speed-up your videos speeding-up (or removing) silences, using FFmpeg.

![Homescreen](screenshots/Homescreen.png)

*Read this in other languages: [English](README.md), [Italian](README.it.md).*

## Table of Contents
  - [Installation](#installation)
    - [Requirements](#requirements)
  - [How it works](#how-it-works)
    - [Front-end](#front-end)
      - [Default interface](#default-interface)
      - [Progress interface](#progress-interface)
    - [Back-end](#back-end)
      - [Note](#note)
  - [Credits](#credits)

## Installation
This program is packaged with [``electron-packager``](https://electron.github.io/electron-packager/master/), and it should work out-of-the-box. If you want to run this program by yourself from the source code, then you need to:

1.  [Download/Install NodeJS](https://nodejs.org/en/) if not yet installed;

2.  [Create a new empty Electron application](https://www.electronjs.org/docs/tutorial/quick-start?lang=en-US);

    ```script
    mkdir silence-speedup && cd silence-speedup
    npm init -y
    npm i --save-dev electron
    ```

3.  Copy&Paste all files inside your application folder;

4.  [Download/Install FFmpeg](https://ffmpeg.org/download.html);

5.  Open ``code/index.js``, go to ``class FFmpeg`` and replace the value of ``command`` (``null``) with the path of the executable of ffmpeg (or its command);

    ``static command = null;`` ➜ ``static command = "path/to/ffmpeg";``

6.  Now you can run the app.

    ```bash
    npm test
    ```

### Requirements
In ``win32`` and ``darwin`` builds, ``ffmpeg`` executable is included in the package; on ``linux`` you need to install it manually.

## How it works

### Front-end

#### Default interface
![Default interface](screenshots/Default%20interface.png)

#### Progress interface
![Progress interface](screenshots/Progress%20interface.png)

### Back-end
For each video, this program will:

1.  Run ffmpeg with ``silencedetect`` filter, in order to get the list of silences' start/end timestamps.

    ```bash
    <ffmpeg bin> -hide_banner -vn \
      -ss 0.00 -i <Input file> \
      -af silencedetect=n=<threshold>:d=<duration> \
      -f null -
    ```

2.  Using that list, split the original video in a tmp folder, applying a speed filter, if any.

    ```bash
    <ffmpeg bin> -hide_banner -loglevel warning -stats \
      -ss <Start time> -to <End time> -i <Input file> \
      -filter_complex "[0:v]<setpts filter>[v];[0:a]<atempo filter>[a]" \
      -map [v] -map [a] <Output fragment>
    ```

3.  Concatenate all the fragments generated before.

    ```bash
    <ffmpeg bin> -hide_banner -loglevel warning -stats \
      -f concat -safe 0 \
      -i <Fragment list file> \
      -c copy \
      -map v -map a <Output file> -y
    ```

#### Note
At the end of execution, the program does not automatically clean the tmp folder.

## Credits
This software uses libraries from the FFmpeg project, which I do not own, under the LGPLv2.1.
