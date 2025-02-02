/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

const { ipcRenderer } = require("electron");

ipcRenderer.on("init", (event, data) => {
    // console.log(data);
    document.title += " | " + data.filename;
    Player.init(data.setting.silenceSpeed.replace("x", ""), data.setting.playbackSpeed.replace("x", ""));
    Player.load({ url: data.filepath, playbackRate: data.setting.playbackSpeed.replace("x", ""), silences: data.silences, margin: data.setting.silenceMargin }, false);
});

class Player {
    // static player, wrapper, background, video;
    // static source, setting, hasJustLoaded;
    // static minPlaybackRate, maxPlaybackRate;

    static init(fastRate = 8, normalRate = 1) {
        /* Editable configuration */
        Player.minPlaybackRate = 0.5; // Lowest playbackRate
        Player.maxPlaybackRate = 3;   // Highest playbackRate

        Player.player = videojs("my-player", {
            fill: true,
            controls: true,
            autoplay: false,
            preload: "auto",
            playbackRates: ["0.5", "0.6", "0.7", "0.8", "0.9", "1", "1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7", "1.8", "1.9", "2", "2.2", "2.5", "2.8", "3"],
            rewind: true,
            plugins: {
                notifier: {
                    defaultTimeout: 1500
                },
                silences: {
                    fastRate: fastRate,
                    normalRate: normalRate,
                    displayRealRemainingTime: true,
                    onSkip: (newTime) => {
                        Player.notify(secondsToTime(newTime));
                    }
                }
            }
        });

        Player.initWrapperFunctions();
        Player.initShortcuts();
    }

    static unavailable() {
        return Player.source == null || Player.source == undefined;
    }

    static initWrapperFunctions() {
        // player's methods
        [
            "src",
            "play", "pause", "paused",
            "userActive",
            "seeking", "currentTime", "duration",
            "muted", "volume",
            "isFullscreen", "requestFullscreen", "exitFullscreen",
            "playbackRate", "defaultPlaybackRate",
            "videoWidth", "videoHeight"
        ].forEach((fn) => {
            Player[fn] = (_value) => {
                if (Player.unavailable())
                    return;

                return Player.player[fn](_value);
            };
        });

        // Plugins
        [
            "notify",
            "isInSilence", "skipCurrentSilence", "setNormalRate", "getNormalRate", "getFastRate",
            "shouldDisplayRealRemainingTime", "setSilenceTimestamps",
        ].forEach((fn) => {
            Player[fn] = Player.player[fn];
        });
    }

    static initShortcuts() {
        document.body.addEventListener("keyup", (e) => {
            if (e.target.tagName == "INPUT" || e.target.tagName == "TEXTAREA") {
                // Ignore shortcuts when typing.
                return;
            }

            switch (e.code) {
                case "Space": {
                    /* Pause/play the video */
                    e.preventDefault();
                    if (Player.paused()) {
                        Player.play();
                        Player.notify(lang.playing);
                    } else {
                        Player.pause();
                        Player.notify(lang.paused);
                    }
                    break;
                }
                case "KeyM": {
                    /* Mute/unmute the video */
                    e.preventDefault();
                    if (Player.muted()) {
                        Player.muted(false);
                        Player.notify(lang.soundOn);
                    } else {
                        Player.muted(true);
                        Player.notify(lang.soundOff);
                    }
                    break;
                }
                case "KeyF": {
                    /* Toggle fullscreen */
                    e.preventDefault();
                    if (Player.isFullscreen()) {
                        Player.exitFullscreen();
                    } else {
                        Player.requestFullscreen();
                    }
                    break;
                }
                case "KeyS": {
                    e.preventDefault();
                    /* Skip silence */
                    Player.skipCurrentSilence();
                    break;
                }
            }
        });

        document.body.addEventListener("keydown", (e) => {
            if (e.target.tagName == "INPUT" || e.target.tagName == "TEXTAREA") {
                // Ignore shortcuts when typing.
                return;
            }

            switch (e.code) {
                case "Space": {
                    /* Do nothing */
                    e.preventDefault();
                    break;
                }
                case "ArrowLeft": {
                    /* Go back 5s (or 1m with Ctrl) */
                    e.preventDefault();
                    Player.changeTime(e.ctrlKey || e.metaKey ? -60 : -5);
                    break;
                }
                case "ArrowRight": {
                    /* Skip 5s (or 1m with Ctrl) */
                    e.preventDefault();
                    Player.changeTime(e.ctrlKey || e.metaKey ? +60 : +5);
                    break;
                }
                case "ArrowUp": {
                    /* Increase volume by 5% */
                    e.preventDefault();
                    Player.changeVolume(+0.05);
                    break;
                }
                case "ArrowDown": {
                    /* Decrease volume by 5% */
                    e.preventDefault();
                    Player.changeVolume(-0.05);
                    break;
                }
                case "BracketLeft":
                case "NumpadSubtract":
                case "Minus": {
                    if (e.ctrlKey || e.metaKey) {
                        break;
                    }
                    /* Decrease playback rate by 0.1 */
                    e.preventDefault();
                    Player.changePlaybackRate(-0.1);
                    break;
                }
                case "BracketRight":
                case "NumpadAdd":
                case "Equal": {
                    if (e.ctrlKey || e.metaKey) {
                        break;
                    }
                    /* Increase playback rate by 0.1 */
                    e.preventDefault();
                    Player.changePlaybackRate(+0.1);
                    break;
                }
            }
        });
    }

    static on(_event, _function) {
        return Player.player.on(_event, _function);
    }

    static load(_source, _autoplay = true) {
        if (_source == null || _source == undefined) {
            return;
        }

        Player.pause();

        // Save the source playbackRate before anything change
        let playbackRateBackup = _source.playbackRate;

        Player.hasJustLoaded = true;
        Player.source = _source;
        Player.src(Player.source.url);
        Player.setNormalRate(Player.source.playbackRate);

        // Restore source's time and playbackRate
        Player.currentTime(Player.source.mark);
        Player.defaultPlaybackRate(playbackRateBackup);

        Player.setSilenceTimestamps(Player.source.silences, Player.source.margin);

        if (_autoplay) {
            Player.play();
        }
    }

    static changeVolume(_amount) {
        if (Player.unavailable()) {
            return;
        }

        let newVolume = limit(+Player.volume() + +_amount, 0, 1);

        Player.volume(newVolume);
        Player.notify(`${lang.volume} ${(newVolume * 100).toFixed(0)}%`);
    }

    static changePlaybackRate(_amount) {
        if (Player.unavailable()) {
            return;
        }

        let newPlaybackRate = limit(+Player.source.playbackRate + +_amount, Player.minPlaybackRate, Player.maxPlaybackRate).toFixed(1);

        Player.playbackRate(newPlaybackRate);
        Player.notify(`${lang.rate} ${newPlaybackRate}x`);
    }

    static changeTime(_amount) {
        if (Player.unavailable()) {
            return;
        }

        let newTime = limit(+Player.currentTime() + +_amount, 0, Player.duration() - 0.1);

        Player.currentTime(newTime);
        Player.notify(secondsToTime(newTime));
    }
}

function secondsToTime(seconds, withDecimals = false) {
    let hours = (Math.floor(seconds / 3600)).toString().padStart(2, "0");
    seconds %= 3600;
    let minutes = (Math.floor(seconds / 60)).toString().padStart(2, "0");
    seconds = withDecimals ? (seconds % 60).toFixed(2).padStart(5, "0") : (Math.floor(seconds % 60)).toString().padStart(2, "0");
    return `${hours}:${minutes}:${seconds}`;
}
