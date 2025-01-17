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
    static shell

    static load() {
        Shell.shell = document.getElementById("shell")

        ipcRenderer.on("cleanShell", (event) => {
            Shell.shell.innerHTML = ""
        })
    }

    static log(msg) {
        let newDiv = document.createElement("div")
        newDiv.appendChild(document.createTextNode(msg))
        Shell.shell.appendChild(newDiv)
        Shell.shell.scrollTop = Shell.shell.scrollHeight
    }

    static err(msg) {
        let newDiv = document.createElement("div")
        newDiv.appendChild(document.createTextNode(msg))
        newDiv.setAttribute("class", "error")
        Shell.shell.appendChild(newDiv)
        Shell.shell.scrollTop = Shell.shell.scrollHeight
    }

    static warn(msg) {
        let newDiv = document.createElement("div")
        newDiv.appendChild(document.createTextNode(msg))
        newDiv.setAttribute("class", "warning")
        Shell.shell.appendChild(newDiv)
        Shell.shell.scrollTop = Shell.shell.scrollHeight
    }
}
