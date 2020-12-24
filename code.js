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

const {ipcRenderer, shell} = require("electron")
const {spawn, spawnSync} = require("child_process")
const fs = require("fs")
const path = require("path")
const os = require("os")

const Shell = require("./assets/classes/shell.js")
const Interface = require("./assets/classes/interface.js")
const Config = require("./assets/classes/config.js")
const FFmpeg = require("./assets/classes/ffmpeg.js")
const EntryList = require("./assets/classes/entrylist.js")
const Entry = require("./assets/classes/entry.js")
const SpeedUp = require("./assets/classes/speedup.js")

window.onload = () => {
  Config.load()
  Shell.load()
  Interface.load()
  FFmpeg.load()
}

ipcRenderer.on("preferencesUpdate", (event, data) => {
  Config.update(data)
  Interface.update()
  FFmpeg.updateCommand()
})
