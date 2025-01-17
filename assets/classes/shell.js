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
