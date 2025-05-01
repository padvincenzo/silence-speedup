/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

const path = require("path");
const i18next = require("i18next");
const Backend = require("i18next-fs-backend");

let initialized = false;

async function initI18n(language = "en") {
    if (initialized) {
        return i18next;
    }

    await i18next
        .use(Backend)
        .init({
            backend: {
                loadPath: path.join(__dirname, "../locales/{{lng}}/translation.json"),
            },
            lng: language,
            fallbackLng: "en",
            preload: ["en", "it"],
        });

    initialized = true;
    return i18next;
}

module.exports = {
    initI18n,
    i18next,
    t: (...args) => i18next.t(...args),
};
