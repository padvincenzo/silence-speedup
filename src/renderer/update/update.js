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

ipcRenderer.on("data", (event, version, content, link) => {
    document.getElementById("version").innerHTML = version
    document.getElementById("content").innerHTML = content
    document.getElementById("download").setAttribute("href", link)
});
