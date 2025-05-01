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
const { initI18n, i18next, t } = require("../../i18n");

window.onload = async () => {
    const { language } = ipcRenderer.sendSync("getInitialData");
    await initI18n(language);

    updateTexts();
}

ipcRenderer.on("languageChanged", async (event, lang) => {
    await i18next.changeLanguage(lang);
    updateTexts();
});

function updateTexts() {
    const div = document.getElementById("ffmpeg-info");
    const platform = os.platform();

    switch (platform) {
        case "darwin":
        case "win32":
        case "linux":
            readmePath = path.join(__dirname, "../../../assets/ffmpeg", "readme.html");
            fs.readFile(readmePath, { encoding: "utf-8" }, (err, data) => {
                if (err) {
                    div.innerHTML = t("ffmpeg.errorReadme");
                } else {
                    div.innerHTML = data.length == 0 ? "-" : data;
                }
            });
            break;

        default:
            div.innerHTML = t("ffmpeg.missing");
    }

    const elements = document.querySelectorAll("[class^='i18n']");
    elements.forEach(el => {
        el.innerHTML = t(el.className.replace("i18n-", "").replace("-", "."));
    });
}
