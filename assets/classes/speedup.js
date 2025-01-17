/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

const codec_audio = "aac";
const codec_video = "libx264";

/**
 * TUNE
 * film – use for high quality movie content; lowers deblocking
 * animation – good for cartoons; uses higher deblocking and more reference frames
 * grain – preserves the grain structure in old, grainy film material
 * stillimage – good for slideshow-like content
 * fastdecode – allows faster decoding by disabling certain filters
 * zerolatency – good for fast encoding and low-latency streaming
 */

module.exports = class SpeedUp {
    static stream = null;
    static interrupted = true;
    static currentEntry = null;

    static threshold;
    static silenceMinimumDuration;
    static silenceMargin;
    static dropAudio;
    static muteAudio;
    static silenceSpeed;
    static playbackSpeed;
    static videoExtension;

    static silenceDetectOptions = [
        "-hide_banner",   // Prevent ffmpeg initial banner                  [ 0]
        "-dn", "-vn",     // Discard data and video                         [ 1,  2]
        "-ss", "0.00",    // Start from 0                                   [ 3,  4]
        "-i", null,       // Input file                                     [ 5,  6]
        "-af", null,      // Silencedetect filter                           [ 7,  8]
        "-f", "null",     // Output format: null (no output)                [ 9, 10]
        "-"               // Dummy output filename                          [11]
    ];

    static exportOptions = {
        playback: {
            options: [
                "-hide_banner",                     // Prevent ffmpeg initial banner                  [ 0]
                "-y",                               // Overwrite file if it already exists            [ 1]
                "-loglevel", "warning",             // Shows only warnings+ messages                  [ 2,  3]
                "-stats",                           // Print stats                                    [ 4]
                "-dn",                              // Discard data                                   [ 5]
                "-ss", null,                        // Start time                                     [ 6,  7]
                "-to", null,                        // End time                                       [ 8,  9]
                "-i", null,                         // Input file                                     [10, 11]
                "-map_metadata", "-1",              // Discard metadata                               [12, 13]
                "-map_chapters", "-1",              // Discard chapters info                          [14, 15]
                "-segment_time_metadata", "0",      // Discard segment time metadata                  [16, 17]
                "-max_muxing_queue_size", "99999",  // Increase memory limit                          [18, 19]
                "-c:a", codec_audio,                // Set the audio codec                            [20, 21]
                "-c:v", codec_video,                // Set the video codec                            [22, 23]
                "-preset", null,                    // Set a default set of options                   [24, 25]
                "-crf", null,                       // Set constant frame quality                     [26, 27]
                "-vsync", "cfr",                    // Sync video as constant frame rate              [28, 29]
                "-fflags", "+genpts"                // Generate fresh timestamps                      [30, 31]
            ],
            index: 32                             // Index for output file
        },
        silence: {
            options: [
                "-hide_banner",                     // Prevent ffmpeg initial banner                  [ 0]
                "-y",                               // Overwrite file if it already exists            [ 1]
                "-loglevel", "warning",             // Shows only warnings+ messages                  [ 2,  3]
                "-stats",                           // Print stats                                    [ 4]
                "-dn",                              // Discard data                                   [ 5]
                "-ss", null,                        // Start time                                     [ 6,  7]
                "-to", null,                        // End time                                       [ 8,  9]
                "-i", null,                         // Input file                                     [10, 11]
                "-map_metadata", "-1",              // Discard metadata                               [12, 13]
                "-map_chapters", "-1",              // Discard chapters info                          [14, 15]
                "-segment_time_metadata", "0",      // Discard segment time metadata                  [16, 17]
                "-max_muxing_queue_size", "99999",  // Increase memory limit                          [18, 19]
                "-c:a", codec_audio,                // Set the audio codec                            [20, 21]
                "-c:v", codec_video,                // Set the video codec                            [22, 23]
                "-preset", null,                    // Set a default set of options                   [24, 25]
                "-crf", null,                       // Set constant frame quality                     [26, 27]
                "-vsync", "cfr",                    // Sync video as constant frame rate              [28, 29]
                "-fflags", "+genpts"                // Generate fresh timestamps                      [30, 31]
            ],
            index: 32                             // Index for output file
        }
    };

    static concatOptions = [
        "-hide_banner",                         // Prevent ffmpeg initial banner                  [ 0]
        "-y",                                   // Overwrite output file if already exists        [ 1]
        "-loglevel", "warning",                 // Shows only warnings+ messages                  [ 2,  3]
        "-stats",                               // Print stats                                    [ 4]
        "-segment_time_metadata", "0",          // Discard segment time metadata                  [ 5,  6]
        // "-r", null,                             // Frame rate                                     [ 7,  8]
        "-vsync", "cfr",                        // Sync video as constant frame rate              [ 7,  8]
        "-f", "concat",                         // Concat multiple videos                         [ 9, 10]
        "-safe", "0",                           // Security option (stackoverflow.com/a/56029574) [11, 12]
        "-i", null,                             // Input file                                     [13, 14]
        "-c:a", "copy",                         // Copy audio codec without reencoding            [15, 16]
        "-c:v", "copy",                         // Copy video codec without reencoding            [17, 18]
        // "-fflags", "+igndts",                   // Ignore DTS                                     [19, 20]
        null                                    // Output file                                    [21]
    ];

    static silenceRegExp = new RegExp(/silence_(start|end): (-?\d+(.\d+)?)/, "gm");

    static setOptions() {

        SpeedUp.threshold = Config.data.thresholds[Interface.threshold.value].value;
        SpeedUp.silenceMinimumDuration = parseFloat(Interface.silenceMinimumDuration.value);
        SpeedUp.silenceMargin = parseFloat(Interface.silenceMargin.value);
        SpeedUp.silenceSpeed = Config.data.speeds[Interface.silenceSpeed.value].text;
        SpeedUp.dropAudio = (SpeedUp.silenceSpeed == "remove");
        SpeedUp.muteAudio = (SpeedUp.dropAudio ? false : muteAudio.checked);
        SpeedUp.playbackSpeed = Config.data.speeds[Interface.playbackSpeed.value].text;
        SpeedUp.videoExtension = Interface.videoExtension.value;

        SpeedUp.silenceDetectOptions[8] = `silencedetect=n=${SpeedUp.threshold}:d=${SpeedUp.silenceMinimumDuration + 2 * SpeedUp.silenceMargin}`;

        SpeedUp.exportOptions.silence.options[25] = SpeedUp.exportOptions.playback.options[25] = Interface.preset.value;
        SpeedUp.exportOptions.silence.options[27] = SpeedUp.exportOptions.playback.options[27] = Interface.crf.value;

        // SpeedUp.concatOptions[8] = Interface.fps.value;
        SpeedUp.concatOptions[14] = Config.fragmentListPath;
    }

    static setFilters() {

        SpeedUp.exportOptions.silence.options.splice(32);
        SpeedUp.exportOptions.playback.options.splice(32);
        SpeedUp.exportOptions.silence.index = SpeedUp.exportOptions.playback.index = 32;

        if (!SpeedUp.dropAudio) {

            if (Interface.tune.value != "-") {
                SpeedUp.exportOptions.silence.index = SpeedUp.exportOptions.silence.options.push(
                    "-tune", Interface.tune.value
                );
            }

            if (Interface.audioRate.value != "-") {
                SpeedUp.exportOptions.silence.index = SpeedUp.exportOptions.silence.options.push(
                    "-ar", Interface.audioRate.value
                );
            }

            if (SpeedUp.silenceSpeed == "1x") {
                SpeedUp.exportOptions.silence.index = SpeedUp.exportOptions.silence.options.push(
                    "-vf", `fps=${Interface.fps.value}`
                );

                if (SpeedUp.muteAudio) {
                    SpeedUp.exportOptions.silence.index = SpeedUp.exportOptions.silence.options.push(
                        "-af", "volume=enable=0"
                    );
                }
            } else {
                SpeedUp.exportOptions.silence.index = SpeedUp.exportOptions.silence.options.push(
                    "-vf", `${Config.data.speeds[Interface.silenceSpeed.value].video},fps=${Interface.fps.value}`,
                    "-af", SpeedUp.muteAudio ? "volume=enable=0" : Config.data.speeds[Interface.silenceSpeed.value].audio
                );
            }
        }

        if (Interface.tune.value != "-") {
            SpeedUp.exportOptions.playback.index = SpeedUp.exportOptions.playback.options.push(
                "-tune", Interface.tune.value
            );
        }

        if (Interface.audioRate.value != "-") {
            SpeedUp.exportOptions.playback.index = SpeedUp.exportOptions.playback.options.push(
                "-ar", Interface.audioRate.value
            );
        }

        if (SpeedUp.playbackSpeed == "1x") {
            SpeedUp.exportOptions.playback.index = SpeedUp.exportOptions.playback.options.push(
                "-vf", `fps=${Interface.fps.value}`
            );
        } else {
            SpeedUp.exportOptions.playback.index = SpeedUp.exportOptions.playback.options.push(
                "-vf", `${Config.data.speeds[Interface.playbackSpeed.value].video},fps=${Interface.fps.value}`,
                "-af", Config.data.speeds[Interface.playbackSpeed.value].audio
            );
        }

        console.log("Options", SpeedUp.exportOptions);
    }

    static async start() {
        SpeedUp.interrupted = false;
        Interface.viewStop();

        SpeedUp.setOptions();
        SpeedUp.setFilters();

        var entries = EntryList.values;
        var len = entries.length;

        if (len == 0) {
            Shell.log("No video queued.");
            Interface.viewStart();
            return;
        }

        ipcRenderer.send("progressUpdate", "total", len);

        for (let i = 0; i < len; i++) {
            entries[i].prepare();
        }

        for (let i = 0; i < len && !SpeedUp.interrupted; i++) {
            let entry = entries[i];
            SpeedUp.currentEntry = entry; // Only for interrupt

            if (SpeedUp.videoExtension != "keep") {
                entry.changeExtension(SpeedUp.videoExtension);
            }

            Interface.setProgressBar(i / len);
            ipcRenderer.send("progressUpdate", "completed", i);

            await SpeedUp.process(entries[i]);

            SpeedUp.currentEntry = null;
        }

        if (SpeedUp.interrupted) {
            return;
        }

        SpeedUp.end();
    }

    static async process(entry) {
        let error = false;
        entry.highlight();

        error = await SpeedUp.silenceDetect(entry);
        if (SpeedUp.interrupted || error) {
            return;
        }

        if (!entry.hasSilences()) {
            entry.finished();
            return;
        }

        error = await SpeedUp.exportFragments(entry);
        if (SpeedUp.interrupted || error) {
            return;
        }

        error = await SpeedUp.concatFragments(entry);
        if (SpeedUp.interrupted || error) {
            return;
        }

        entry.finished();
    }

    static interrupt() {

        Shell.err("Stopping...");
        SpeedUp.interrupted = true;
        FFmpeg.interrupt();

        if (SpeedUp.currentEntry != null) {
            SpeedUp.currentEntry.gotError("Interrupted");
            SpeedUp.currentEntry = null;
        }

        ipcRenderer.send("progressUpdate", "name", "");
        ipcRenderer.send("progressUpdate", "status", "Interrupted");

        Interface.viewStart();
    }

    static end() {
        Shell.log("All done.");
        FFmpeg.update(null);

        Interface.setProgressBar(1);
        ipcRenderer.send("progressUpdate", "name", "");

        Interface.viewStart();
    }

    static reportError(msg, entry) {
        entry.gotError("Failed");
        Shell.err(msg);
    }

    static async silenceDetect(entry) {
        if (SpeedUp.interrupted) {
            return;
        }

        entry.status = "Detecting silences...";
        Shell.log("Detecting silences...");

        SpeedUp.silenceDetectOptions[6] = entry.url;

        return await FFmpeg.run(
            SpeedUp.silenceDetectOptions,
            { entry: entry },
            (str, data) => {
                let res = null;

                while ((res = SpeedUp.silenceRegExp.exec(str)) != null) {
                    data.entry.appendTS(res[1], parseFloat(res[2]).toFixed(7), SpeedUp.silenceMargin);
                }
            },
            (data) => {
                if (data.entry.tsCheck()) {
                    if (data.entry.hasSilences()) {
                        Shell.log(`${data.entry.silencePercentage()} % of the video detected as silence.`);
                    } else {
                        Shell.log("No silences detected, moving on to the next.");
                    }
                    return;
                }

                SpeedUp.reportError("Data error: indexes do not match.", data.entry);
            },
            (data) => {
                SpeedUp.reportError("Sorry, no fragments found. Moving on to the next.", data.entry);
            })
    }

    static async exportFragments(entry) {
        if (SpeedUp.interrupted) {
            return true;
        }

        SpeedUp.exportOptions.playback.options[11] = SpeedUp.exportOptions.silence.options[11] = entry.url;

        entry.status = "Exporting...";
        Shell.log("Exporting...");

        SpeedUp.videoExtension = Interface.videoExtension.value == "keep"
            ? entry.extension
            : Interface.videoExtension.value;
        SpeedUp.stream = fs.createWriteStream(Config.fragmentListPath, { flags: 'w' });

        let sf = entry.silenceTS;
        let n = sf.start.length - 1;
        let c = 0;
        let i = 0;
        let error = false;

        var counter = {
            count: 0,
            name: function (extension) {
                let number = this.count.toString().padStart(6, "0");
                this.count += 1;
                let name = `f_${number}.${extension}`;
                let fragmentPath = path.join(Config.tmpPath, name);
                if (fs.existsSync(fragmentPath)) {
                    fs.unlinkSync(fragmentPath);
                }
                SpeedUp.stream.write(`file '${fragmentPath}'\n`);
                return fragmentPath;
            }
        };

        if (sf.start[0] != "0.00") {
            error = await SpeedUp.exportPlaybackFragment(entry, "0.00", sf.start[0], counter);
            if (error) {
                return error;
            }
        }

        for (i = 0; i < n && !SpeedUp.interrupted; i++) {
            error = await SpeedUp.exportSilenceFragment(entry, sf.start[i], sf.end[i], counter);
            if (error) {
                return error;
            }
            error = await SpeedUp.exportPlaybackFragment(entry, sf.end[i], sf.start[i + 1], counter);
            if (error) {
                return error;
            }
        }

        error = await SpeedUp.exportSilenceFragment(entry, sf.start[i], sf.end[i], counter);
        if (error) {
            return error;
        }

        if (sf.end[i] < entry.seconds) {
            error = await SpeedUp.exportPlaybackFragment(entry, sf.end[i], entry.seconds, counter);
            if (error) {
                return error;
            }
        }

        return error;
    }

    static async exportSilenceFragment(entry, startTS, endTS, counter) {
        if (SpeedUp.interrupted) {
            return true;
        }

        if (SpeedUp.dropAudio) {
            return false;
        }

        if (parseFloat(endTS) - parseFloat(startTS) <= 0.002) {
            return false;
        }

        SpeedUp.exportOptions.silence.options[7] = startTS;
        SpeedUp.exportOptions.silence.options[9] = endTS;
        let output = counter.name(entry.outputExtension);
        SpeedUp.exportOptions.silence.options[SpeedUp.exportOptions.silence.index] = output;

        let error = await FFmpeg.run(SpeedUp.exportOptions.silence.options, { entry: entry, startTS: startTS, endTS: endTS }, null, null, (data) => {
            Shell.warn(`Fragment [${data.startTS} - ${data.endTS} got filtering error.`);
        });

        return error;
    }

    static async exportPlaybackFragment(entry, startTS, endTS, counter) {
        if (SpeedUp.interrupted) {
            return true;
        }

        if (parseFloat(endTS) - parseFloat(startTS) <= 0.002) {
            return false;
        }

        SpeedUp.exportOptions.playback.options[7] = startTS;
        SpeedUp.exportOptions.playback.options[9] = endTS;
        let output = counter.name(entry.outputExtension);
        SpeedUp.exportOptions.playback.options[SpeedUp.exportOptions.playback.index] = output;

        let error = await FFmpeg.run(SpeedUp.exportOptions.playback.options, { entry: entry, startTS: startTS, endTS: endTS }, null, null, (data) => {
            Shell.warn(`Fragment [${data.startTS} - ${data.endTS} got filtering error.`);
        });

        return error;
    }

    static async concatFragments(entry) {
        if (SpeedUp.stream != null) {
            SpeedUp.stream.end();
            SpeedUp.stream = null;
        }

        if (SpeedUp.interrupted) {
            return true;
        }

        entry.status = "Concatenating...";
        Shell.log("Concatenating...");

        SpeedUp.concatOptions[SpeedUp.concatOptions.length - 1] = path.join(Config.data.exportPath, entry.outputName);

        return await FFmpeg.run(SpeedUp.concatOptions, { entry: entry }, null, null, (data) => {
            SpeedUp.reportError("Error during concatenation.", data.entry);
        });
    }
};
