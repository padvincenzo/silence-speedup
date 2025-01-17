/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

const { ipcRenderer, shell } = require("electron");
const { spawn, spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");
const Shell = require("../../classes/shell.js");
const Interface = require("../../classes/interface.js");
const Config = require("../../classes/config.js");
const FFmpeg = require("../../classes/ffmpeg.js");
const EntryList = require("../../classes/entrylist.js");
const Entry = require("../../classes/entry.js");
const SpeedUp = require("../../classes/speedup.js");

window.onload = () => {
    Config.load();
    Shell.load();
    Interface.load();
    FFmpeg.load();
};

ipcRenderer.on("preferencesUpdate", (event, data) => {
    Config.update(data);
    Interface.update();
    FFmpeg.updateCommand();
});
