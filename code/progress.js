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

let total
let completed
let currentVideo
let currentStatus
let progressBar

window.onload = () => {
  total = document.getElementById("total")
  completed = document.getElementById("completed")
  currentVideo = document.getElementById("currentVideo")
  currentStatus = document.getElementById("currentStatus")
  progressBar = document.getElementById("progressBar")

  document.getElementById("maximize").addEventListener("click", (event) => {
    ipcRenderer.send("viewMainWindow")
  })
}

ipcRenderer.on("changeTotal", (event, value) => {
  total.innerHTML = "/" + value
})

ipcRenderer.on("changeCompleted", (event, value) => {
  completed.innerHTML = value
})

ipcRenderer.on("changeName", (event, value) => {
  currentVideo.innerHTML = value
})

ipcRenderer.on("changeStatus", (event, value) => {
  currentStatus.innerHTML = value
})

ipcRenderer.on("changeProgressBar", (event, value) => {
  progressBar.style.width = value + "%"
})
