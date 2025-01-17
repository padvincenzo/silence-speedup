/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

module.exports = class FFmpeg {
    static command;
    static spawn;

    static progressBar;
    static progress;
    static frame;
    static fps;
    static time;
    static speed;
    static percentage;

    static progressRegExp = new RegExp(/time=\s*(\d+:\d+:\d+\.\d+)\s*.*speed=\s*(\d+(\.\d+)?(e[\+\-]\d+)?x)/);
    static durationRegExp = new RegExp(/(^|\s)(\d+:\d+:\d+\.\d+)/);
    static timeRegExp = new RegExp(/(\d+):(\d+):(\d+)\.(\d+)/);

    static load() {
        FFmpeg.progressBar = document.getElementById("ffmpegProgressBar");
        FFmpeg.progress = document.getElementById("ffmpegProgress");
        FFmpeg.time = document.getElementById("ffmpegProgressTime");
        FFmpeg.speed = document.getElementById("ffmpegProgressSpeed");
        FFmpeg.percentage = document.getElementById("ffmpegPercentage");

        FFmpeg.updateCommand();
    }

    static updateCommand() {
        Interface.viewStart();
        if (Config.data.ffmpegPath == "") {
            if (!fs.existsSync(Config.data.ffmpegPath)) {
                Interface.lock();
                Shell.warn("Please go to File->Preferences and set the path for ffmpeg.");
            } else {
                FFmpeg.command = Config.data.ffmpegPath;
            }
        } else {
            FFmpeg.command = Config.data.ffmpegPath;
        }
    }

    static async run(args, data, onstderr, ifGood, ifBad) {
        if (FFmpeg.spawn != null) {
            Shell.log("FFmpeg is still running; cannot run another process.");
            SpeedUp.interrupted = true;
            return;
        }

        let error = false;
        FFmpeg.spawn = spawn(FFmpeg.command, args);

        for await (var str of FFmpeg.spawn.stderr) {
            if (onstderr != null) {
                onstderr(str, data);
            }
            FFmpeg.update(str.toString(), data.entry.seconds, data.startTS == null ? 0 : data.startTS);
        }

        // Wait until spawn has exited
        await (async () => {
            if (FFmpeg.spawn) {
                while (FFmpeg.spawn.exitCode == undefined) {
                    await new Promise(r => setTimeout(r, 50));
                }
            }
        })();

        error = !SpeedUp.interrupted && FFmpeg.spawn.exitCode != 0;
        if (error) {
            if (!SpeedUp.interrupted && ifBad != null) {
                ifBad(data);
            }
        } else if (ifGood != null) {
            ifGood(data);
        }

        FFmpeg.spawn = null;

        return error;
    }

    static interrupt() {
        if (FFmpeg.spawn != null) {
            FFmpeg.spawn.kill();
            FFmpeg.spawn = null;
        }
    }

    static getSecondsFromTime(time) {
        var res = FFmpeg.timeRegExp.exec(time);
        if (res != null) {
            return parseInt(res[1]) * 3600 + parseInt(res[2]) * 60 + parseInt(res[3]) + parseInt(res[4]) / 100;
        }
        return 0;
    }

    static getTimeFromSeconds(seconds) {
        let hours = (Math.floor(seconds / 3600)).toString().padStart(2, "0");
        seconds %= 3600;
        let minutes = (Math.floor(seconds / 60)).toString().padStart(2, "0");
        seconds = (seconds % 60).toFixed(2).padStart(5, "0");
        return hours + ":" + minutes + ":" + seconds;
    }

    static update(str, duration = null, offsetCurrentTime = "0") {
        if (str == null) {
            FFmpeg.time.innerHTML = "--:--:--.--";
            FFmpeg.speed.innerHTML = "-";
            FFmpeg.percentage.innerHTML = "-.-- %";
            return;
        }

        let progress = FFmpeg.progressRegExp.exec(str);

        if (progress == null) {
            if (SpeedUp.interrupted || /\[silencedetect @|silence_(start|end)|Press \[q\] to stop/.test(str)) {
                return;
            }
            if (/Error|failed/.test(str)) {
                Shell.warn(str)
            } else {
                console.log(str);
            }
            return;
        }

        let time = (offsetCurrentTime == "0")
            ? progress[1]
            : FFmpeg.getTimeFromSeconds(parseFloat(offsetCurrentTime) + FFmpeg.getSecondsFromTime(progress[1]));
        FFmpeg.time.innerHTML = time;
        if (progress[2] != "0x") {
            FFmpeg.speed.innerHTML = progress[2];
        }

        var percentage = ((FFmpeg.getSecondsFromTime(progress[1]) + parseFloat(offsetCurrentTime)) / duration * 100);
        FFmpeg.progressBar.style.width = percentage + "%";
        FFmpeg.percentage.innerHTML = percentage.toFixed(2) + " %";
        ipcRenderer.send("progressUpdate", "progressBar", percentage);
    }

    static getVideoDuration(entry) {
        let options = [
            "-hide_banner",
            "-t", "0.001",
            "-i", entry.url,
            "-f", "null", "-"
        ];

        let test = spawn(FFmpeg.command, options);

        test.stderr.on("data", (err) => {
            let str = err.toString();

            let duration = FFmpeg.durationRegExp.exec(str);
            if (duration != null) {
                entry.duration = duration[2];
            }
        });

        test.on("exit", (code) => {
            if (code != 0 || entry.duration == null) {
                entry.status = "Error occurred";
                Shell.log(`Got error while detecting duration of ${entry.name}.`);
            }
        });
    }
}
