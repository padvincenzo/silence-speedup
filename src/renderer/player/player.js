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
    // Update window title.
    document.title += " | " + data.filename;

    // Init player.
    let playbackSpeed = data.setting.playbackSpeed.replace("x", "");
    let silenceSpeed = data.setting.silenceSpeed == "remove" ? 1 : data.setting.silenceSpeed.replace("x", "");
    console.log(data.silences);
    var player = videojs(
        "my-player",
        {
            fill: true,
            controls: true,
            autoplay: false,
            preload: "auto",
            rewind: true,
            plugins: {
                notifier: {
                    defaultTimeout: 1500
                },
                silenceSpeedUp: {
                    playbackSpeed: playbackSpeed,
                    silenceSpeed: silenceSpeed,
                    timestamps: data.silences,
                    skipSilences: data.setting.silenceSpeed == "remove",
                    displayRealRemainingTime: true,
                }
            }
        }
    );

    // Load source.
    player.src(data.filepath);

    // Init shortcuts
    document.body.addEventListener("keyup", (e) => {
        if (e.target.tagName == "INPUT" || e.target.tagName == "TEXTAREA") {
            // Ignore shortcuts when typing.
            return;
        }

        switch (e.code) {
            case "Space": {
                /* Pause/play the video */
                e.preventDefault();
                if (player.paused()) {
                    player.play();
                    // player.notify(lang.playing);
                } else {
                    player.pause();
                    // player.notify(lang.paused);
                }
                break;
            }
            case "KeyM": {
                /* Mute/unmute the video */
                e.preventDefault();
                if (player.muted()) {
                    player.muted(false);
                    // player.notify(lang.soundOn);
                } else {
                    player.muted(true);
                    // player.notify(lang.soundOff);
                }
                break;
            }
            case "KeyF": {
                /* Toggle fullscreen */
                e.preventDefault();
                if (player.isFullscreen()) {
                    player.exitFullscreen();
                } else {
                    player.requestFullscreen();
                }
                break;
            }
            case "KeyS": {
                e.preventDefault();
                /* Skip silence */
                player.skipCurrentSilence();
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
                player.changeTime(e.ctrlKey || e.metaKey ? -60 : -5);
                break;
            }
            case "ArrowRight": {
                /* Skip 5s (or 1m with Ctrl) */
                e.preventDefault();
                player.changeTime(e.ctrlKey || e.metaKey ? +60 : +5);
                break;
            }
            case "ArrowUp": {
                /* Increase volume by 5% */
                e.preventDefault();
                player.changeVolume(+0.05);
                break;
            }
            case "ArrowDown": {
                /* Decrease volume by 5% */
                e.preventDefault();
                player.changeVolume(-0.05);
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
                player.changePlaybackRate(-0.1);
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
                player.changePlaybackRate(+0.1);
                break;
            }
        }
    });
});
