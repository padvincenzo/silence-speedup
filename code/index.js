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

class Settings {
  static dropZone
  static GUI

  static entryList
  static addFiles
  static addFolder
  static settings
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

    Settings.settings = document.getElementById("settings")
    Settings.settings.addEventListener("click", (event) => {
      // to do
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

    ipcRenderer.send("menuEnabler", true)

    Settings.unlock()
  }

  static viewStop() {
    Settings.start.style.display = "none"
    Settings.stop.style.display = "inline-block"
    Settings.minimize.style.display = "inline-block"

    ipcRenderer.send("menuEnabler", false)

    Settings.lock()
  }

  static setProgressBar(value) {
    ipcRenderer.send("setProgressBar", value)
  }
}

function log(msg) {
  Settings.shell.innerHTML += msg + "\n"
  Settings.shell.scrollTop = Settings.shell.scrollHeight
}

class Config {
  static configPath = path.join(__dirname, "config.json")

  static defaultExportPath = path.join(os.homedir(), "speededup")
  static exportPath = null
  static defaultFFmpegPath = (os.type() == "Windows_NT" ? "ffmpeg.exe" : "ffmpeg")
  static ffmpegPath = null

  static tmpPath = null
  static fragmentListPath = null

  static load() {
    if (!fs.existsSync(Config.configPath)) {
      Config.save(Config.defaultExportPath, Config.defaultFFmpegPath)
    } else {
      let json = fs.readFileSync(Config.configPath, {encoding: 'utf-8'})
      let config = JSON.parse(json)
      Config.exportPath = config.exportPath || Config.defaultExportPath
      Config.ffmpegPath = config.ffmpegPath
    }

    Config.tmpPath = path.join(Config.exportPath, "tmp")
    Config.fragmentListPath = path.join(Config.exportPath, "list.txt")

    if (!fs.existsSync(Config.exportPath))
      fs.mkdirSync(Config.exportPath)

    if (!fs.existsSync(Config.tmpPath))
      fs.mkdirSync(Config.tmpPath)

    log("Export path: " + Config.exportPath)
  }

  static save(exportPath, ffmpegPath) {
    fs.writeFileSync(Config.configPath,
      JSON.stringify({exportPath: exportPath, ffmpegPath:ffmpegPath}),
      {encoding: 'utf-8'})
    Config.exportPath = exportPath
    Config.ffmpegPath = ffmpegPath
  }
}

class FFmpeg {
  static command

  static progressBar
  static progress
  static frame
  static fps
  static time
  static speed

  static info = new RegExp(/ffmpeg version .\..\..-.+ Copyright \(c\) \d+-\d+ the FFmpeg developers/)
  static progressRegExp = new RegExp(/time=\s*(\d+:\d+:\d+\.\d+)\s*.*speed=\s*(\d+(\.\d+)?x)/)
  static durationRegExp = new RegExp(/(^|\s)(\d+:\d+:\d+\.\d+)/)
  static timeRegExp = new RegExp(/(\d+):(\d+):(\d+)\.(\d+)/)

  static load() {
    FFmpeg.progressBar = document.getElementById("ffmpegProgressBar")
    FFmpeg.progress = document.getElementById("ffmpegProgress")
    FFmpeg.time = document.getElementById("ffmpegProgressTime")
    FFmpeg.speed = document.getElementById("ffmpegProgressSpeed")

    FFmpeg.command = Config.ffmpegPath

    FFmpeg.test()
  }

  static test() {
    let test = spawnSync(FFmpeg.command, ["-version"])
    if(test.error != undefined) {
      log("FFmpeg not configured.")
      Settings.lock()
    } else {
      let lines = test.stdout.toString().split("\n")
      if(!FFmpeg.info.test(lines[0])) {
        log("FFmpeg not configured.")
        Settings.lock()
      } else {
        log(lines[0])
      }
    }
  }

  static getSecondsFromTime(time) {
    var res = FFmpeg.timeRegExp.exec(time)
    if(res != null)
      return parseInt(res[1]) * 3600 + parseInt(res[2]) * 60 + parseInt(res[3]) + parseInt(res[4]) / 100
    return 0
  }

  static getTimeFromSeconds(seconds) {
    let hours = (Math.floor(seconds / 3600)).toString().padStart(2, "0")
    seconds %= 3600
    let minutes = (Math.floor(seconds / 60)).toString().padStart(2, "0")
    seconds = (seconds % 60).toFixed(2).padStart(5, "0")
    return hours + ":" + minutes + ":" + seconds
  }

  static update(str, duration = null, offsetCurrentTime = "0") {
    if(str == null) {
      FFmpeg.time.innerHTML = "--:--:--.--"
      FFmpeg.speed.innerHTML = "-"
      return false
    }

    let progress = FFmpeg.progressRegExp.exec(str)

    if(progress == null)
      return false

    let time = (offsetCurrentTime == "0") ? progress[1] : FFmpeg.getTimeFromSeconds(parseFloat(offsetCurrentTime) + FFmpeg.getSecondsFromTime(progress[1]))
    FFmpeg.time.innerHTML = time
    FFmpeg.speed.innerHTML = progress[2]

    var percentage = ((FFmpeg.getSecondsFromTime(progress[1]) + parseFloat(offsetCurrentTime)) / duration * 100)
    FFmpeg.progressBar.style.width = percentage + "%"
    ipcRenderer.send("changeProgressBar", percentage)
    return true
  }

  static getVideoDuration(entry) {
    var options = [
      "-hide_banner",
      "-t", "0.001",
      "-i", entry.url,
      "-f", "null", "-"
    ]

    var test = spawn(FFmpeg.command, options)

    test.stdout.on("data", (data) => SpeedUp.printData)

    test.stderr.on("data", (err) => {
      let str = err.toString()

      let duration = FFmpeg.durationRegExp.exec(str)
      if(duration != null) {
        entry.duration = duration[2]
      }
    })

    test.on("exit", (code) => {
      if(code != 0 || entry.duration == null) {
        entry.status = "Error occurred"
        log("Got error while detecting duration of " + entry.name + ".")
      }
    })
  }
}

class EntryList {
  static list = {}
  static canImport = true

  static import(urls) {
    if(urls == undefined || urls == null)
      return 0

    if(! EntryList.canImport)
      return 0

    let len = urls.length
    if(len == 0)
      return 0

    let c = 0

    for(var i = 0; i < len; i++) {
      let url = urls[i].toString()
      let name = Entry.getNameFromUrl(url)
      let extension = Entry.getExtensionFromName(name)
      if(Entry.isExtensionValid(extension)) {
        if(EntryList.list.hasOwnProperty(name)) {
          log("Cannot load " + name + ": file name already exists.")
        } else {
          var entry = new Entry(url, name, extension)
          EntryList.list[name] = entry
          c++
        }
      }
    }

    return c
  }

  static remove(name) {
    var entry = EntryList.list[name]
    Settings.entryList.removeChild(entry.ref)
    log("File " + entry.name + " removed.")
    delete EntryList.list[name]
  }

  static get values() {
    return Object.values(EntryList.list)
  }
}

class Entry {
  #url = null
  #name = null
  #outputName = null
  #extension = null
  #duration = null
  #seconds = null
  #ref = null
  #progress = null
  #removeBtn = null

  constructor(url, name, extension) {
    this.#url = url
    this.#name = name
    this.#outputName = name
    this.#extension = extension

    this.#ref = document.createElement("div")
    this.#ref.setAttribute("class", "entry")
    this.#ref.setAttribute("title", url)

    var text = document.createElement("div")
    text.setAttribute("class", "entryName")
    text.appendChild(document.createTextNode(this.#name))
    this.#ref.appendChild(text)

    this.#progress = document.createElement("div")
    this.#progress.setAttribute("class", "progress")
    this.#progress.innerHTML = "Caricamento..."
    this.#ref.appendChild(this.#progress)

    this.#removeBtn = document.createElement("div")
    this.#removeBtn.setAttribute("class", "remove")
    this.#removeBtn.appendChild(document.createTextNode("×"))
    this.#removeBtn.addEventListener("click", (event) => {
      EntryList.remove(this.#name)
    })
    this.#ref.appendChild(this.#removeBtn)

    FFmpeg.getVideoDuration(this)

    Settings.entryList.appendChild(this.#ref)
  }

  get ref() {
    return this.#ref
  }

  get url() {
    return this.#url
  }

  get name() {
    return this.#name
  }

  get extension() {
    return this.#extension
  }

  changeExtension(newExtension) {
    let lastDot = name.lastIndexOf(".")
    this.#outputName = this.#name.substring(0, lastDot) + newExtension
  }

  get outputName() {
    return this.#outputName
  }

  set duration(duration) {
    if(duration == null) {
      this.status = "Loaded"
      return
    }

    if(this.#duration != null)
      return

    this.#duration = duration
    this.#seconds = FFmpeg.getSecondsFromTime(duration)
    this.status = "Loaded [" + this.#duration + "]"
  }

  get duration() {
    return this.#duration
  }

  get seconds() {
    return this.#seconds
  }

  set status(status) {
    this.#progress.innerHTML = status
    ipcRenderer.send("changeStatus", status)
  }

  prepare() {
    this.status = "Queued"
    this.#removeBtn.style.display = "none"
    this.#ref.style.backgroundColor = "initial"
    this.#ref.style.color = "var(--c-dark)"
  }

  highlight() {
    this.#ref.style.backgroundColor = "var(--c-1)"
	  this.#ref.style.color = "var(--c-light)"
    log("Started working on " + this.#name + ".")
    ipcRenderer.send("changeName", this.#name)
  }

  gotError(err) {
    this.#progress.innerHTML = err
    this.#ref.style.backgroundColor = "var(--c-5)"
  }

  finished() {
    this.#ref.style.backgroundColor = "var(--c-3)"
    this.#ref.style.color = "var(--c-light)"
    this.status = "Completed"
    log(this.#outputName + " completed.")
  }

  static getNameFromUrl(url) {
    var lastSlash = url.lastIndexOf("/")
    var lastBackSlash = url.lastIndexOf("\\")
    return url.substr(Math.max(lastSlash, lastBackSlash) + 1)
  }

  static getExtensionFromName(name) {
    var lastDot = name.lastIndexOf(".")
    if(lastDot < 1)
      return false

    return name.substr(lastDot + 1)
  }

  static isExtensionValid(extension) {
    return /avi|mkv|mp4/.test(extension)
  }
}

class SpeedUp {
  static spawn = null
  static stream = null
  static interrupted = true

  static threshold
  static silenceMinimumDuration
  static silenceMargin
  static dropAudio
  static muteAudio
  static silenceSpeed
  static playbackSpeed
  static videoExtension = "mp4"

  static silenceDetectOptions = [
    "-hide_banner",
    "-vn",
    "-ss", "0.00",
    "-i", null,                             // Input file
    "-af", null,                            // silencedetect filter
    "-f", "null",
    "-"
  ]

  static exportOptions = {
    "playback": {
      "options": [
        "-hide_banner",
        "-loglevel", "warning",
        "-stats",
        "-ss", null,                        // Start time
        "-to", null,                        // End time
        "-i", null                          // Input file
      ],
      "index": 10                           // Index for output file
    },
    "silence": {
      "options": [
        "-hide_banner",
        "-loglevel", "warning",
        "-stats",
        "-ss", null,                        // Start time
        "-to", null,                        // End time
        "-i", null                          // Input file
      ],
      "index": 10                           // Index for output file
    },
    "copy": {
      "options": [
        "-hide_banner",
        "-loglevel", "warning",
        "-stats",
        "-ss", null,                        // Start time
        "-to", null,                        // End time
        "-i", null,                         // Input file
        "-c", "copy",
        null,                               // Output file
        "-y"
      ]
    }
  }

  static mergeOptions = [
    "-hide_banner",
    "-loglevel", "warning",
    "-stats",
    "-f", "concat",
    "-safe", "0",
    "-i", null,                             // Input file
    "-c", "copy",
    "-map", "v",
    "-map", "a",
    null,                                   // Output file
    "-y"
  ]

  static silenceRegExp = new RegExp(/silence_(start|end): (-?\d+(.\d+)?)/, "gm")

  static setOptions() {
    SpeedUp.threshold = Settings.thresholds[Settings.threshold.value].value
    SpeedUp.silenceMinimumDuration = parseFloat(Settings.silenceMinimumDuration.value)
    SpeedUp.silenceMargin = parseFloat(Settings.silenceMargin.value)
    SpeedUp.silenceSpeed = Settings.speed[Settings.silenceSpeed.value].text
    SpeedUp.dropAudio = (SpeedUp.silenceSpeed == "remove")
    SpeedUp.muteAudio = (SpeedUp.dropAudio ? false : muteAudio.checked)
    SpeedUp.playbackSpeed = Settings.speed[Settings.playbackSpeed.value].text
    SpeedUp.videoExtension = Settings.videoExtension.value

    SpeedUp.silenceDetectOptions[7] = "silencedetect=n=" + SpeedUp.threshold + ":d=" + (SpeedUp.silenceMinimumDuration + 2 * SpeedUp.silenceMargin)
    SpeedUp.mergeOptions[9] = Config.fragmentListPath
  }

  static setFilters() {

    if(! SpeedUp.dropAudio) {

      SpeedUp.exportOptions.silence.options.splice(10, 7)
      SpeedUp.exportOptions.silence.index = 10

      if(SpeedUp.silenceSpeed == "1x") {
        if(SpeedUp.muteAudio) {
          SpeedUp.exportOptions.silence.options[10] = "-af"
          SpeedUp.exportOptions.silence.options[11] = "volume=enable=0"
          SpeedUp.exportOptions.silence.index = 12
        }
      } else {
        let videoFilter = Settings.speed[Settings.silenceSpeed.value].video
        let audioFilter = SpeedUp.muteAudio ? "[0:a]volume=enable=0[a]" : Settings.speed[Settings.silenceSpeed.value].audio
        SpeedUp.exportOptions.silence.options[10] = "-filter_complex"
        SpeedUp.exportOptions.silence.options[11] = videoFilter + audioFilter
        SpeedUp.exportOptions.silence.options[12] = "-map"
        SpeedUp.exportOptions.silence.options[13] = "[v]"
        SpeedUp.exportOptions.silence.options[14] = "-map"
        SpeedUp.exportOptions.silence.options[15] = "[a]"
        SpeedUp.exportOptions.silence.index = 16
      }
    }

    SpeedUp.exportOptions.playback.options.splice(10, 7)
    SpeedUp.exportOptions.playback.index = 10

    if(SpeedUp.playbackSpeed != "1x") {
      let videoFilter = Settings.speed[Settings.playbackSpeed.value].video
      let audioFilter = Settings.speed[Settings.playbackSpeed.value].audio
      SpeedUp.exportOptions.playback.options[10] = "-filter_complex"
      SpeedUp.exportOptions.playback.options[11] = videoFilter + audioFilter
      SpeedUp.exportOptions.playback.options[12] = "-map"
      SpeedUp.exportOptions.playback.options[13] = "[v]"
      SpeedUp.exportOptions.playback.options[14] = "-map"
      SpeedUp.exportOptions.playback.options[15] = "[a]"
      SpeedUp.exportOptions.playback.index = 16
    }
  }

  static printData(data) {
    console.log(data)
  }

  static start() {
    SpeedUp.interrupted = false
    SpeedUp.setOptions()
    SpeedUp.setFilters()

    var entries = EntryList.values
    var len = entries.length

    if(len == 0) {
      log("No video queued.")
      Settings.viewStart()
      return
    }

    for(var i = 0; i < len; i++)
      entries[i].prepare()

    ipcRenderer.send("changeTotal", len)

    SpeedUp.init(entries, 0, len)
  }

  static interrupt() {
    if(SpeedUp.interrupted)
      return

    SpeedUp.interrupted = true

    SpeedUp.spawn.kill()
    log("Stopping...")
    ipcRenderer.send("changeName", "")

    Settings.viewStart()
  }

  static end() {
    log("All done.")
    FFmpeg.update(null)

    ipcRenderer.send("changeName", "")

    Settings.viewStart()
  }

  static reportError(msg, code, entries, i, len) {
    entries[i].gotError("Fallito [" + code + "]")
    log(msg)
    SpeedUp.init(entries, i + 1, len)
  }

  static init(entries, i, len) {
    Settings.setProgressBar(i / len)

    ipcRenderer.send("changeCompleted", i)

    if(i == len) {
      SpeedUp.end()
      return
    }

    if(SpeedUp.interrupted)
      return

    entries[i].highlight()

    let url = entries[i].url
    SpeedUp.silenceDetectOptions[5] = url
    SpeedUp.exportOptions.playback.options[9] = url
    SpeedUp.exportOptions.silence.options[9] = url
    SpeedUp.exportOptions.copy.options[9] = url
    SpeedUp.mergeOptions[16] = path.join(Config.exportPath, entries[i].outputName)

    SpeedUp.silenceDetect(entries, i, len)
  }

  static silenceDetect(entries, i, len) {
    if(SpeedUp.interrupted)
      return

    entries[i].status = "Detecting silences..."
    log("Detecting silences...")

    // log(SpeedUp.silenceDetectOptions)
    SpeedUp.spawn = spawn(FFmpeg.command, SpeedUp.silenceDetectOptions)

    let silenceFragments = {
      "start": {
        "ts": [],
        "index": 0,
        "offset": SpeedUp.silenceMargin
      },
      "end": {
        "ts": [],
        "index": 0,
        "offset": - SpeedUp.silenceMargin
      }
    }

    SpeedUp.spawn.stdout.on("data", (data) => SpeedUp.printData)

    SpeedUp.spawn.stderr.on("data", (err) => {
      var str = err.toString()
      var hasCaptured = false
      var res = null

      while((res = SpeedUp.silenceRegExp.exec(str)) != null) {
        silenceFragments[res[1]].ts.push(parseFloat(res[2]))
        let index = silenceFragments[res[1]].index
        silenceFragments[res[1]].index += 1
        if(index > 0)
          silenceFragments[res[1]].ts[index] += silenceFragments[res[1]].offset
        hasCaptured = true
      }

      if(! hasCaptured) {
        if(! FFmpeg.update(str, entries[i].seconds))
          console.log(str)
      }
    })

    SpeedUp.spawn.on("exit", (code) => {
      if(code == 0) {
        if(silenceFragments.start.index == silenceFragments.end.index) {
          if(silenceFragments.start.index == 0) {
            log("No silences detected, moving on to the next.")
            SpeedUp.init(entries, i + 1, len)
          } else {
            let seconds = 0.0
            for(let j = 0; j < silenceFragments.start.index; j++)
              seconds += silenceFragments.end.ts[j] - silenceFragments.start.ts[j]
            log((seconds / entries[i].seconds * 100).toFixed(2) + "% of video detected as silence.")
            SpeedUp.exportFragments(entries, i, len, silenceFragments)
          }
        } else SpeedUp.reportError("Data error: indexes do not match.", code, entries, i, len)
      } else {
        if(! SpeedUp.interrupted)
          SpeedUp.reportError("Sorry, no fragments found. Moving on to the next.", code, entries, i, len)
      }
    })
  }

  static exportFragments(entries, i, len, silenceFragments) {
    if(SpeedUp.interrupted)
      return

    entries[i].status = "Exporting..."
    log("Exporting...")

    SpeedUp.videoExtension = Settings.videoExtension.value == "keep" ? entries[i].extension : Settings.videoExtension.value
    SpeedUp.stream = fs.createWriteStream(Config.fragmentListPath, {flags:'w'})

    let n = silenceFragments.start.index
    SpeedUp.exportPlaybackFragment(entries, i, len, silenceFragments, -1, n, 0)
  }

  static getFragmentName(c) {
    let name = path.join(Config.tmpPath, "f_" + c.toString().padStart(6, "0") + "." + SpeedUp.videoExtension)
    if(fs.existsSync(name))
      fs.unlinkSync(name)
    SpeedUp.stream.write("file '" + name + "'\n")
    return name
  }

  static exportSilenceFragment(entries, i, len, silenceFragments, j, n, c) {
    if(SpeedUp.interrupted)
      return

    if(j == n) {
      SpeedUp.mergeFragments(entries, i, len, c)
      return
    }

    let startTime = silenceFragments.start.ts[j].toFixed(2)
    let endTime = silenceFragments.end.ts[j].toFixed(2)

    if(SpeedUp.dropAudio) {

      SpeedUp.exportPlaybackFragment(entries, i, len, silenceFragments, j, n, c)

    } else {

      SpeedUp.exportOptions.silence.options[5] = startTime
      SpeedUp.exportOptions.silence.options[7] = endTime
      let output = SpeedUp.getFragmentName(c)
      SpeedUp.exportOptions.silence.options[SpeedUp.exportOptions.silence.index] = output

      SpeedUp.spawn = spawn(FFmpeg.command, SpeedUp.exportOptions.silence.options)

      SpeedUp.spawn.stdout.on("data", (data) => SpeedUp.printData)

      SpeedUp.spawn.stderr.on("data", (err) => {
        let str = err.toString()
        if(! FFmpeg.update(str, entries[i].seconds, startTime))
          console.log(str)
      })

      SpeedUp.spawn.on("exit", (code) => {
        if(code == 0)
          SpeedUp.exportPlaybackFragment(entries, i, len, silenceFragments, j, n, c + 1)
        else {
          if(! SpeedUp.interrupted)
            SpeedUp.exportCopiedFragment(startTime, endTime, output, "playback", entries, i, len, silenceFragments, j, n, c + 1)
        }
      })
    }
  }

  static exportPlaybackFragment(entries, i, len, silenceFragments, j, n, c) {
    if(SpeedUp.interrupted)
      return

    if(j > n) {
      SpeedUp.mergeFragments(entries, i, len, c)
      return
    }

    let startTime
    let endTime

    if(j == -1) {
      if(silenceFragments.start.ts[0] > 0) {
        startTime = "0.00"
        endTime = silenceFragments.start.ts[0].toFixed(2)
      } else {
        SpeedUp.exportSilenceFragment(entries, i, len, silenceFragments, 0, n, c)
        return
      }
    } else {
      startTime = silenceFragments.end.ts[j].toFixed(2)
      endTime = (j == n - 1) ? entries[i].seconds.toFixed(2) : silenceFragments.start.ts[j + 1].toFixed(2)
    }

    SpeedUp.exportOptions.playback.options[5] = startTime
    SpeedUp.exportOptions.playback.options[7] = endTime
    let output = SpeedUp.getFragmentName(c)
    SpeedUp.exportOptions.playback.options[SpeedUp.exportOptions.playback.index] = output

    SpeedUp.spawn = spawn(FFmpeg.command, SpeedUp.exportOptions.playback.options)

    SpeedUp.spawn.stdout.on("data", (data) => SpeedUp.printData)

    SpeedUp.spawn.stderr.on("data", (err) => {
      let str = err.toString()
      if(! FFmpeg.update(str, entries[i].seconds, startTime))
        console.log(str)
    })

    SpeedUp.spawn.on("exit", (code) => {
      if(code == 0)
        SpeedUp.exportSilenceFragment(entries, i, len, silenceFragments, j + 1, n, c + 1)
      else {
        if(! SpeedUp.interrupted)
          SpeedUp.exportCopiedFragment(startTime, endTime, output, "silence", entries, i, len, silenceFragments, j + 1, n, c + 1)
      }
    })
  }

  static exportCopiedFragment(ss, to, out, next, entries, i, len, silenceFragments, j, n, c) {
    log("Fragment [" + ss + " - " + to + "] got filter error, trying to copy.")

    SpeedUp.exportOptions.copy.options[5] = ss
    SpeedUp.exportOptions.copy.options[7] = to
    SpeedUp.exportOptions.copy.options[11] = out

    SpeedUp.spawn = spawn(FFmpeg.command, SpeedUp.exportOptions.copy.options)

    SpeedUp.spawn.stdout.on("data", (data) => SpeedUp.printData)

    SpeedUp.spawn.stderr.on("data", (err) => {
      let str = err.toString()
      if(! FFmpeg.update(str, entries[i].seconds, ss))
        console.log(str)
    })

    SpeedUp.spawn.on("exit", (code) => {
      if(code == 0) {
        log("Fragment copied succesfully.")
        switch (next) {
          case "playback": {
            SpeedUp.exportPlaybackFragment(entries, i, len, silenceFragments, j, n, c)
            break
          }
          case "silence": {
            SpeedUp.exportSilenceFragment(entries, i, len, silenceFragments, j, n, c)
            break
          }
          default: {
            // Nothing
          }
        }
      } else {
        if(! SpeedUp.interrupted)
          SpeedUp.reportError("Non sono riuscito a copiare il frammento. Passo al prossimo video.", code, entries, i, len)
      }
    })
  }

  static mergeFragments(entries, i, len, c) {
    SpeedUp.stream.end()

    entries[i].status = "Concatenating..."
    log("Concatenating...")

    SpeedUp.spawn = spawn(FFmpeg.command, SpeedUp.mergeOptions)

    SpeedUp.spawn.stdout.on("data", (data) => SpeedUp.printData)

    SpeedUp.spawn.stderr.on("data", (err) => {
      var str = err.toString()
      if(! FFmpeg.update(str, entries[i].seconds))
        console.log(str)
    })

    SpeedUp.spawn.on("exit", (code) => {
      if(code == 0) {
        entries[i].finished()
        SpeedUp.init(entries, i + 1, len)
      } else {
        if(! SpeedUp.interrupted)
          SpeedUp.reportError("Non sono riuscito a unire i frammenti. Passo al prossimo video.", code, entries, i, len)
      }
    })
  }

}

window.onload = () => {
  Settings.load()
  Config.load()
  FFmpeg.load()
}

ipcRenderer.on("selectedFiles", (event, fileNames) => {
  if(fileNames == undefined)
    return

  c = EntryList.import(fileNames)
  log("Files added: " + c)
})

ipcRenderer.on("selectFilesRequested", (event) => {
  if(EntryList.canImport)
    ipcRenderer.send("selectFiles")
})

ipcRenderer.on("selectedFolder", (event, folder) => {
  if(folder == undefined)
    return

  var list = fs.readdirSync(folder[0])
  urls = list.map(name => path.join(folder[0], name))

  log("Files added: " + EntryList.import(urls))
})

ipcRenderer.on("selectFolderRequested", (event) => {
  if(EntryList.canImport)
    ipcRenderer.send("selectFolder")
})

ipcRenderer.on("start", (event) => {
  SpeedUp.start()
})

ipcRenderer.on("stop", (event) => {
  SpeedUp.interrupt()
})

ipcRenderer.on("stopAndExit", (event) => {
  SpeedUp.interrupt()
  ipcRenderer.send("quit")
})
