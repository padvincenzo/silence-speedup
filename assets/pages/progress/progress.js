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

let total;
let completed;
let currentVideo;
let currentStatus;
let progressBar;

window.onload = () => {
    total = document.getElementById("count-total");
    completed = document.getElementById("count-completed");
    currentVideo = document.getElementById("current-video");
    currentStatus = document.getElementById("current-status");
    progressBar = document.getElementById("progress-bar");

    document.getElementById("default-mode").addEventListener("click", (event) => {
        ipcRenderer.send("switchToDefaultMode");
    });
};

ipcRenderer.on("total", (event, value) => {
    total.innerHTML = value;
});

ipcRenderer.on("completed", (event, value) => {
    completed.innerHTML = value;
});

ipcRenderer.on("name", (event, value) => {
    currentVideo.innerHTML = value;
});

ipcRenderer.on("status", (event, value) => {
    currentStatus.innerHTML = value;
});

ipcRenderer.on("progressBar", (event, value) => {
    progressBar.style.width = value + "%";
});
