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
const os = require("os");
const fs = require("fs");
const path = require("path");

window.onload = () => {
    let div = document.getElementById("ffmpeg-info");

    if (platform() == "darwin" || platform() == "win32" || platform() == "linux") {
        readmePath = path.join(__dirname, "..", "..", "ffmpeg", "readme.html");
        readFile(readmePath, { encoding: 'utf-8' }, (err, data) => {
            if (err) {
                div.innerHTML = "Error reading readme file";
            } else {
                div.innerHTML = data;
            }
        });

    } else {
        div.innerHTML = "FFmpeg not configured for this platform.";
    }
}
