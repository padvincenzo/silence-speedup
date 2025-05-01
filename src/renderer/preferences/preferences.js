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
const { initI18n, i18next, t } = require("../../i18n");

const configPath = path.join(__dirname, "..", "..", "..", "config.json");
const configPathDefaults = path.join(__dirname, "..", "..", "..", "config.json.example");
const defaultExportPath = path.join(os.homedir(), "speededup");
const defaultFFmpegPath = path.join(__dirname, "..", "..", "ffmpeg", (os.type() == "Windows_NT" ? "ffmpeg.exe" : "ffmpeg"));

let data;

ipcRenderer.on("languageChanged", async (event, lang) => {
    await i18next.changeLanguage(lang);
    updateTexts();
});

window.onload = async () => {
    if (!fs.existsSync(configPath)) {
        // Copy initial configuration.
        fs.copyFileSync(configPathDefaults, configPath);
    }

    let json = fs.readFileSync(configPath, { encoding: "utf-8" });
    data = JSON.parse(json);
    setData();

    document.getElementById("export-browse").addEventListener("click", (event) => {
        let folder = ipcRenderer.sendSync("exportChoose");
        if (folder == undefined) {
            return;
        }

        document.getElementById("export").value = folder[0].toString();
    });

    document.getElementById("ffmpeg-browse").addEventListener("click", (event) => {
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

    const { language } = ipcRenderer.sendSync("getInitialData");
    await initI18n(language);

    updateTexts();
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

function updateTexts() {
    const elements = document.querySelectorAll("span[class^='i18n']");
    elements.forEach(el => {
        el.innerHTML = t(el.className.replace("i18n-", "").replace("-", "."));
    });
}
