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

class Settings {
  static dropZone
  static GUI

  static entryList
  static addFiles
  static addFolder
  static configuration
  static info

  static start
  static stop
  static minimize
  static shell

  static threshold
  static thresholdValue
  static silenceMinimumDuration
  static silenceMargin
  static muteAudio
  static silenceSpeed
  static silenceSpeedValue
  static playbackSpeed
  static playbackSpeedValue
  static videoExtension

  static speed = [
    {                                       // 0
      "text":"0.5x",
      "video": "[0:v]setpts=2*PTS[v];",
      "audio": "[0:a]atempo=0.5[a]"
    },
    {                                       // 1
      "text":"0.8x",
      "video": "[0:v]setpts=1.25*PTS[v];",
      "audio": "[0:a]atempo=0.8[a]"
    },
    {                                       // 2
      "text":"1x",
      "video": "",
      "audio": ""
    },
    {                                       // 3
      "text":"1.25x",
      "video": "[0:v]setpts=0.8*PTS[v];",
      "audio": "[0:a]atempo=1.25[a]"
    },
    {                                       // 4
      "text":"1.6x",
      "video": "[0:v]setpts=0.625*PTS[v];",
      "audio": "[0:a]atempo=1.6[a]"
    },
    {                                       // 5
      "text":"2x",
      "video": "[0:v]setpts=0.5*PTS[v];",
      "audio": "[0:a]atempo=2[a]"
    },
    {                                       // 6
      "text":"2.5x",
      "video": "[0:v]setpts=0.4*PTS[v];",
      "audio": "[0:a]atempo=2,atempo=1.25[a]"
    },
    {                                       // 7
      "text":"4x",
      "video": "[0:v]setpts=0.25*PTS[v];",
      "audio": "[0:a]atempo=2,atempo=2[a]"
    },
    {                                       // 8
      "text":"8x",
      "video": "[0:v]setpts=0.125*PTS[v];",
      "audio": "[0:a]atempo=2,atempo=2,atempo=2[a]"
    },
    {                                       // 9
      "text":"20x",
      "video": "[0:v]setpts=0.05*PTS[v];",
      "audio": "[0:a]atempo=2,atempo=2,atempo=2,atempo=2,atempo=1.25[a]"
    },
    {"text":"remove"}                      // 10
  ]

  static thresholds = [
    {                                       // 0
      "text":"Low",
      "value": "0.002"
    },
    {                                       // 1
      "text":"Mid",
      "value": "0.02"
    },
    {                                       // 2
      "text":"High",
      "value": "0.1"
    }
  ]

  static load() {
    Settings.dropZone = document.getElementById("dropZone")
    Settings.GUI = document.getElementById("GUI")

    Settings.entryList = document.getElementById("entryList")

    Settings.addFiles = document.getElementById("addFiles")
    Settings.addFiles.addEventListener("click", (event) => {
      ipcRenderer.send("selectFiles")
    })

    Settings.addFolder = document.getElementById("addFolder")
    Settings.addFolder.addEventListener("click", (event) => {
      ipcRenderer.send("selectFolder")
    })

    Settings.configuration = document.getElementById("configuration")
    Settings.configuration.addEventListener("click", (event) => {
      ipcRenderer.send("showConfig")
    })

    Settings.info = document.getElementById("info")
    Settings.info.addEventListener("click", (event) => {
      ipcRenderer.send("showCredits")
    })

    Settings.start = document.getElementById("start")
    Settings.stop = document.getElementById("stop")

    Settings.start.addEventListener("click", (event) => {
      Settings.viewStop()
      SpeedUp.start()
    })

    Settings.stop.addEventListener("click", (event) => {
      Settings.viewStart()
      SpeedUp.interrupt()
    })

    Settings.shell = document.getElementById("shell")

    Settings.minimize = document.getElementById("minimize")
    Settings.minimize.addEventListener("click", (event) => {
      ipcRenderer.send("viewProgressWindow")
    })

    Settings.threshold = document.getElementById("threshold")
    Settings.thresholdValue = document.getElementById("thresholdValue")
    Settings.threshold.addEventListener("input", (event) => {
      Settings.thresholdValue.innerHTML = Settings.thresholds[Settings.threshold.value].text
    })

    Settings.silenceMinimumDuration = document.getElementById("silenceMinimumDuration")
    Settings.silenceMinimumDurationValue = document.getElementById("silenceMinimumDurationValue")
    Settings.silenceMinimumDuration.addEventListener("input", (event) => {
      Settings.silenceMinimumDurationValue.innerHTML = parseFloat(Settings.silenceMinimumDuration.value).toFixed(2) + "s"
    })

    Settings.silenceMargin = document.getElementById("silenceMargin")
    Settings.silenceMarginValue = document.getElementById("silenceMarginValue")
    Settings.silenceMargin.addEventListener("input", (event) => {
      Settings.silenceMarginValue.innerHTML = parseFloat(Settings.silenceMargin.value).toFixed(2) + "s"
    })

    Settings.muteAudio = document.getElementById("muteAudio")

    Settings.silenceSpeed = document.getElementById("silenceSpeed")
    Settings.silenceSpeedValue = document.getElementById("silenceSpeedValue")
    Settings.silenceSpeed.addEventListener("input", (event) => {
      Settings.silenceSpeedValue.innerHTML = Settings.speed[Settings.silenceSpeed.value].text
      Settings.muteAudio.disabled = (Settings.silenceSpeed.value == 10)
    })

    Settings.playbackSpeed = document.getElementById("playbackSpeed")
    Settings.playbackSpeedValue = document.getElementById("playbackSpeedValue")
    Settings.playbackSpeed.addEventListener("input", (event) => {
      Settings.playbackSpeedValue.innerHTML = Settings.speed[Settings.playbackSpeed.value].text
    })

    Settings.videoExtension = document.getElementById("videoExtension")

    document.body.ondragover = () => {
      Settings.GUI.style.opacity = "0.2"
      Settings.dropZone.innerHTML = EntryList.canImport ? "Drop videos here" : "∅"
      Settings.dropZone.style.boxShadow = "inset 0px 0px 30px var(--c-1)"
      return false
    }

    document.body.ondragleave = () => {
      Settings.GUI.style.opacity = "1"
      Settings.dropZone.style.boxShadow = "none"
      return false
    }

    document.body.ondragend = () => {
      Settings.GUI.style.opacity = "1"
      Settings.dropZone.style.boxShadow = "none"
      return false
    }

    document.body.ondrop = (event) => {
      event.preventDefault()
      Settings.GUI.style.opacity = "1"
      Settings.dropZone.style.boxShadow = "none"

      if(EntryList.canImport) {
        let files = Object.values(event.dataTransfer.files)
        let urls = files.map(file => file.path)
        EntryList.import(urls)
      }

      return false
    }
  }

  static lock() {
    Settings.addFiles.disabled = true
    Settings.addFolder.disabled = true
    Settings.start.disabled = true
    Settings.stop.disabled = false
    Settings.minimize.disabled = false

    Settings.threshold.disabled = true
    Settings.silenceMinimumDuration.disabled = true
    Settings.silenceMargin.disabled = true
    Settings.muteAudio.disabled = true
    Settings.silenceSpeed.disabled = true
    Settings.playbackSpeed.disabled = true
    // Settings.videoExtension.disabled = true

    EntryList.canImport = false
  }

  static unlock() {
    Settings.addFiles.disabled = false
    Settings.addFolder.disabled = false
    Settings.start.disabled = false
    Settings.stop.disabled = true
    Settings.minimize.disabled = true

    Settings.threshold.disabled = false
    Settings.silenceMinimumDuration.disabled = false
    Settings.silenceMargin.disabled = false
    Settings.muteAudio.disabled = (Settings.silenceSpeed.value == 10)
    Settings.silenceSpeed.disabled = false
    Settings.playbackSpeed.disabled = false
    // Settings.videoExtension.disabled = false

    EntryList.canImport = true
  }

  static viewStart() {
    Settings.start.style.display = "inline-block"
    Settings.stop.style.display = "none"
    Settings.minimize.style.display = "none"
    Settings.configuration.disabled = false

    ipcRenderer.send("menuEnabler", true)

    Settings.unlock()
  }

  static viewStop() {
    Settings.start.style.display = "none"
    Settings.stop.style.display = "inline-block"
    Settings.minimize.style.display = "inline-block"
    Settings.configuration.disabled = true

    ipcRenderer.send("menuEnabler", false)

    Settings.lock()
  }

  static setProgressBar(value) {
    ipcRenderer.send("setProgressBar", value)
  }
}

module.exports = Settings
