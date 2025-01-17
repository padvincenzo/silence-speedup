/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

module.exports = class Shell {
    static shell;

    static load() {
        Shell.shell = document.getElementById("shell");

        ipcRenderer.on("cleanShell", (event) => {
            Shell.shell.innerHTML = "";
        });
    }

    static print(msg, level) {
        let now = new Date();
        let line = document.createElement("div");
        line.setAttribute("class", level);
        line.innerHTML = `[${now.toLocaleString()}] ${msg}`;
        Shell.shell.appendChild(line);

        // Follow the log.
        Shell.shell.scrollTop = Shell.shell.scrollHeight;
    }

    static log(msg) {
        Shell.print(msg, "");
    }

    static err(msg) {
        Shell.print(msg, "error");
    }

    static warn(msg) {
        Shell.print(msg, "warning");
    }
}
