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
    static shellToggle;

    static load() {
        Shell.shell = document.getElementById("shell");
        Shell.shellToggle = document.getElementById("shell-toggle");

        Shell.shellToggle.addEventListener("click", () => {
            Shell.shell.classList.toggle("d-none");
        });

        ipcRenderer.on("cleanShell", (event) => {
            Shell.shell.innerHTML = "";
        });
    }

    static print(message, level) {
        let now = new Date();
        let line = document.createElement("div");
        line.setAttribute("class", level);
        line.innerHTML = `[${now.toLocaleString()}] ${message}`;
        Shell.shell.appendChild(line);

        // Follow the log.
        Shell.shell.scrollTop = Shell.shell.scrollHeight;
    }

    static log(message) {
        Shell.print(message, "text-light");
    }

    static err(message) {
        Shell.print(message, "bg-danger text-light");
    }

    static warn(message) {
        Shell.print(message, "bg-warning text-dark");
    }

    static success(message) {
        Shell.print(message, "bg-success text-light");
    }
}
