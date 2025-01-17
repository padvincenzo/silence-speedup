/**
 * Silence SpeedUp
 * Speed-up your videos speeding-up (or removing) silences, using FFmpeg.
 * This is an electron-based app.
 *
 * Copyright (C) 2025  Vincenzo Padula
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

const { ipcRenderer } = require("electron");
const fs = require("fs");
const path = require("path");
const os = require("os");

const configPath = join(__dirname, "..", "..", "..", "config.json");
const defaultExportPath = join(homedir(), "speededup");
const defaultFFmpegPath = join(__dirname, "..", "..", "ffmpeg", (type() == "Windows_NT" ? "ffmpeg.exe" : "ffmpeg"));

let data;

window.onload = () => {
    let json = readFileSync(configPath, { encoding: 'utf-8' });
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
    document.getElementById("export").value = ((data.exportPath == "" && existsSync(defaultExportPath)) ? defaultExportPath : data.exportPath);
    document.getElementById("ffmpeg").value = ((data.ffmpegPath == "" && existsSync(defaultFFmpegPath)) ? defaultFFmpegPath : data.ffmpegPath);
}

function getData() {
    data.exportPath = document.getElementById("export").value;
    if (data.exportPath == "") {
        data.exportPath = defaultExportPath;
    }
    data.ffmpegPath = document.getElementById("ffmpeg").value;
    if (data.ffmpegPath == "") {
        if (existsSync(defaultFFmpegPath)) {
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

    writeFileSync(configPath,
        JSON.stringify(data, null, "\t"),
        { encoding: 'utf-8' });
}
