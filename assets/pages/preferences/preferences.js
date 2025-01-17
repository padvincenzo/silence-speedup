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
const fs = require("fs");
const path = require("path");
const os = require("os");

const configPath = path.join(__dirname, "..", "..", "..", "config.json");
const defaultExportPath = path.join(os.homedir(), "speededup");
const defaultFFmpegPath = path.join(__dirname, "..", "..", "ffmpeg", (os.type() == "Windows_NT" ? "ffmpeg.exe" : "ffmpeg"));

let data;

window.onload = () => {
    let json = fs.readFileSync(configPath, { encoding: "utf-8" });
    data = JSON.parse(json);
    setData();

    document.getElementById("exportChoose").addEventListener("click", (event) => {
        let folder = ipcRenderer.sendSync("exportChoose");
        if (folder == undefined) {
            return;
        }

        document.getElementById("export").value = folder[0].toString();
    });

    document.getElementById("ffmpegChoose").addEventListener("click", (event) => {
        let file = ipcRenderer.sendSync("ffmpegChoose");
        if (file == undefined) {
            return;
        }

        document.getElementById("ffmpeg").value = file[0].toString();
    });

    document.getElementById("reset").addEventListener("click", (event) => {
        setData();
    });

    document.getElementById("save").addEventListener("click", (event) => {
        getData();
        saveData();
    });
};

function setData() {
    document.getElementById("export").value = ((data.exportPath == "" && fs.existsSync(defaultExportPath)) ? defaultExportPath : data.exportPath);
    document.getElementById("ffmpeg").value = ((data.ffmpegPath == "" && fs.existsSync(defaultFFmpegPath)) ? defaultFFmpegPath : data.ffmpegPath);
}

function getData() {
    data.exportPath = document.getElementById("export").value;
    if (data.exportPath == "") {
        data.exportPath = defaultExportPath;
    }
    data.ffmpegPath = document.getElementById("ffmpeg").value;
    if (data.ffmpegPath == "") {
        if (fs.existsSync(defaultFFmpegPath)) {
            data.ffmpegPath = defaultFFmpegPath;
        } else {
            // Do nothing
        }
    }
}

function saveData() {
    ipcRenderer.send("preferencesUpdate", data);

    if (data.ffmpegPath == defaultFFmpegPath) {
        data.ffmpegPath = "";
    }

    fs.writeFileSync(configPath,
        JSON.stringify(data, null, "\t"),
        { encoding: "utf-8" });
}
