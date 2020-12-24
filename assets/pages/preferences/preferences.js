/*
Silence SpeedUp
Speed-up your videos speeding-up (or removing) silences, using FFmpeg.
This is an electron-based app.

Copyright (C) 2020  Vincenzo Padula

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

const {ipcRenderer} = require("electron")
const fs = require("fs")
const path = require("path")
const os = require("os")

const configPath = "config.json"
const defaultExportPath = path.join(os.homedir(), "speededup")

let exportPath = null

function load() {
  let json = fs.readFileSync(configPath, {encoding: 'utf-8'})
  let config = JSON.parse(json)
  exportPath = config.exportPath || defaultExportPath

  document.getElementById("export").value = exportPath
}

function save() {
  exportPath = document.getElementById("export").value

  fs.writeFileSync(configPath,
    JSON.stringify({exportPath:exportPath}),
    {encoding: 'utf-8'})
}

window.onload = () => {

   document.getElementById("exportChoose").addEventListener("click", (event) => {
     ipcRenderer.send("exportChoose")
   })

   document.getElementById("reset").addEventListener("click", (event) => {
     document.getElementById("export").value = defaultExportPath
     save()
   })

   document.getElementById("save").addEventListener("click", (event) => {
     save()
   })
}

ipcRenderer.on("exportChoosen", (event, folder) => {
  if(folder == undefined)
    return

  document.getElementById("export").value = folder[0].toString()
})
