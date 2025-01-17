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

module.exports = class Interface {
    static dropZone
    static gui

    static entryList
    static addFiles
    static addFolder
    static preferences
    static about

    static start
    static stop
    static progressMode

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

    static crf
    static fps
    static preset
    static audioRate
    static tune

    static load() {
        Interface.dropZone = document.getElementById("dropZone")
        Interface.gui = document.getElementById("gui")

        Interface.entryList = document.getElementById("entryList")

        Interface.addFiles = document.getElementById("addFiles")
        Interface.addFiles.addEventListener("click", (event) => {
            ipcRenderer.send("selectFiles")
        })

        Interface.addFolder = document.getElementById("addFolder")
        Interface.addFolder.addEventListener("click", (event) => {
            ipcRenderer.send("selectFolder")
        })

        Interface.preferences = document.getElementById("preferences")
        Interface.preferences.addEventListener("click", (event) => {
            ipcRenderer.send("showPreferences")
        })

        Interface.about = document.getElementById("about")
        Interface.about.addEventListener("click", (event) => {
            ipcRenderer.send("showAbout")
        })

        Interface.start = document.getElementById("start")
        Interface.stop = document.getElementById("stop")

        Interface.start.addEventListener("click", (event) => {
            SpeedUp.start()
        })

        Interface.stop.addEventListener("click", (event) => {
            SpeedUp.interrupt()
        })

        Interface.progressMode = document.getElementById("progressMode")
        Interface.progressMode.addEventListener("click", (event) => {
            ipcRenderer.send("switchToProgressMode")
        })

        Interface.threshold = document.getElementById("threshold")
        Interface.thresholdValue = document.getElementById("thresholdValue")
        Interface.threshold.addEventListener("input", (event) => {
            Interface.thresholdValue.innerHTML = Config.data.thresholds[Interface.threshold.value].text
        })

        Interface.silenceMinimumDuration = document.getElementById("silenceMinimumDuration")
        Interface.silenceMinimumDurationValue = document.getElementById("silenceMinimumDurationValue")
        Interface.silenceMinimumDuration.addEventListener("input", (event) => {
            Interface.silenceMinimumDurationValue.innerHTML = parseFloat(Interface.silenceMinimumDuration.value).toFixed(2) + "s"
        })

        Interface.silenceMargin = document.getElementById("silenceMargin")
        Interface.silenceMarginValue = document.getElementById("silenceMarginValue")
        Interface.silenceMargin.addEventListener("input", (event) => {
            Interface.silenceMarginValue.innerHTML = parseFloat(Interface.silenceMargin.value).toFixed(2) + "s"
        })

        Interface.muteAudio = document.getElementById("muteAudio")
        Interface.silenceSpeed = document.getElementById("silenceSpeed")
        Interface.silenceSpeedValue = document.getElementById("silenceSpeedValue")
        Interface.silenceSpeed.addEventListener("input", (event) => {
            Interface.silenceSpeedValue.innerHTML = Config.data.speeds[Interface.silenceSpeed.value].text
            Interface.muteAudio.disabled = (Interface.silenceSpeed.value == Config.data.speeds.length - 1)
        })

        Interface.playbackSpeed = document.getElementById("playbackSpeed")
        Interface.playbackSpeedValue = document.getElementById("playbackSpeedValue")
        Interface.playbackSpeed.addEventListener("input", (event) => {
            Interface.playbackSpeedValue.innerHTML = Config.data.speeds[Interface.playbackSpeed.value].text
        })

        Interface.videoExtension = document.getElementById("videoExtension")

        Interface.fps = document.getElementById("fps")
        Interface.preset = document.getElementById("preset")

        Interface.crf = document.getElementById("crf")
        Interface.crfValue = document.getElementById("crfValue")
        Interface.crf.addEventListener("input", (event) => {
            Interface.crfValue.innerHTML = Interface.crf.value
        })

        Interface.audioRate = document.getElementById("audioRate")
        Interface.tune = document.getElementById("tune")

        Interface.update()

        document.body.ondragover = () => {
            Interface.gui.style.opacity = "0.2"
            Interface.dropZone.innerHTML = EntryList.canImport ? "Drop videos here" : "∅"
            Interface.dropZone.style.boxShadow = "inset 0px 0px 30px var(--c-1)"
            return false
        }

        document.body.ondragleave = () => {
            Interface.gui.style.opacity = "1"
            Interface.dropZone.style.boxShadow = "none"
            return false
        }

        document.body.ondragend = () => {
            Interface.gui.style.opacity = "1"
            Interface.dropZone.style.boxShadow = "none"
            return false
        }

        document.body.ondrop = (event) => {
            event.preventDefault()
            Interface.gui.style.opacity = "1"
            Interface.dropZone.style.boxShadow = "none"

            if (EntryList.canImport) {
                let files = Object.values(event.dataTransfer.files)
                let urls = files.map(file => file.path)
                EntryList.import(urls)
            }

            return false
        }

        ipcRenderer.on("selectedFiles", (event, fileNames) => {
            if (fileNames == undefined)
                return

            let c = EntryList.import(fileNames)
            Shell.log(`Files added: ${c}`)
        })

        ipcRenderer.on("selectedFolder", (event, folder) => {
            if (folder == undefined)
                return

            var list = fs.readdirSync(folder[0])
            var urls = list.map(name => path.join(folder[0], name))

            let c = EntryList.import(urls)
            Shell.log(`Files added: ${c}`)
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
    }

    static update() {
        Interface.threshold.setAttribute("max", Config.data.thresholds.length - 1)
        Interface.threshold.value = Config.data.initialThreshold
        Interface.thresholdValue.innerHTML = Config.data.thresholds[Interface.threshold.value].text

        Interface.silenceMinimumDuration.setAttribute("min", parseFloat(Config.data.silenceMinimumDuration.min))
        Interface.silenceMinimumDuration.setAttribute("max", parseFloat(Config.data.silenceMinimumDuration.max))
        Interface.silenceMinimumDuration.setAttribute("step", parseFloat(Config.data.silenceMinimumDuration.step))
        Interface.silenceMinimumDuration.value = parseFloat(Config.data.silenceMinimumDuration.initialValue)
        Interface.silenceMinimumDurationValue.innerHTML = parseFloat(Config.data.silenceMinimumDuration.initialValue).toFixed(2) + "s"

        Interface.silenceMargin.setAttribute("min", parseFloat(Config.data.silenceMargin.min))
        Interface.silenceMargin.setAttribute("max", parseFloat(Config.data.silenceMargin.max))
        Interface.silenceMargin.setAttribute("step", parseFloat(Config.data.silenceMargin.step))
        Interface.silenceMargin.value = parseFloat(Config.data.silenceMargin.initialValue)
        Interface.silenceMarginValue.innerHTML = parseFloat(Config.data.silenceMargin.initialValue).toFixed(2) + "s"

        Interface.silenceSpeed.setAttribute("max", parseInt(Config.data.speeds.length - 1))
        Interface.silenceSpeed.value = parseInt(Config.data.initialSilenceSpeed)
        Interface.silenceSpeedValue.innerHTML = Config.data.speeds[Config.data.initialSilenceSpeed].text
        Interface.muteAudio.disabled = (Config.data.initialSilenceSpeed == Config.data.speeds.length - 1)

        Interface.playbackSpeed.setAttribute("max", Config.data.speeds.length - 2)
        Interface.playbackSpeed.value = Config.data.initialPlaybackSpeed
        Interface.playbackSpeedValue.innerHTML = Config.data.speeds[Config.data.initialPlaybackSpeed].text

        let options = ""
        Config.data.formats.forEach((format, i) => {
            options += `<option value="${format.value}">${format.label}</option>`
        })
        Interface.videoExtension.innerHTML = options

        options = ""
        Config.data.presets.forEach((preset, i) => {
            options += `<option value="${preset.value}"${Config.data.initialPreset == i ? " selected" : ""}>${preset.label}</option>`
        })
        Interface.preset.innerHTML = options

        options = ""
        Config.data.fps.forEach((fps, i) => {
            options += `<option value="${fps.value}"${Config.data.initialFps == i ? " selected" : ""}>${fps.label}</option>`
        })
        Interface.fps.innerHTML = options

        Interface.crf.value = Config.data.initialCrf
        Interface.crfValue.innerHTML = Interface.crf.value

        options = ""
        Config.data.audioRates.forEach((audioRate, i) => {
            options += `<option value="${audioRate.value}"${Config.data.initialAudioRate == i ? " selected" : ""}>${audioRate.label}</option>`
        })
        Interface.audioRate.innerHTML = options

        options = ""
        Config.data.tunes.forEach((tune, i) => {
            options += `<option value="${tune.value}">${tune.label}</option>`
        })
        Interface.tune.innerHTML = options
    }

    static lock() {
        Interface.addFiles.disabled = true
        Interface.addFolder.disabled = true
        Interface.start.disabled = true
        Interface.stop.disabled = false
        Interface.progressMode.disabled = true

        Interface.threshold.disabled = true
        Interface.silenceMinimumDuration.disabled = true
        Interface.silenceMargin.disabled = true
        Interface.muteAudio.disabled = true
        Interface.silenceSpeed.disabled = true
        Interface.playbackSpeed.disabled = true
        Interface.videoExtension.disabled = true
        Interface.crf.disabled = true
        Interface.fps.disabled = true
        Interface.preset.disabled = true
        Interface.audioRate.disabled = true
        Interface.tune.disabled = true

        EntryList.canImport = false
        ipcRenderer.send("menuEnabler", "lock")
    }

    static unlock() {
        Interface.addFiles.disabled = false
        Interface.addFolder.disabled = false
        Interface.start.disabled = false
        Interface.stop.disabled = true
        Interface.progressMode.disabled = true

        Interface.threshold.disabled = false
        Interface.silenceMinimumDuration.disabled = false
        Interface.silenceMargin.disabled = false
        Interface.muteAudio.disabled = (Interface.silenceSpeed.value == 10)
        Interface.silenceSpeed.disabled = false
        Interface.playbackSpeed.disabled = false
        Interface.videoExtension.disabled = false
        Interface.crf.disabled = false
        Interface.fps.disabled = false
        Interface.preset.disabled = false
        Interface.audioRate.disabled = false
        Interface.tune.disabled = false

        EntryList.canImport = true
        ipcRenderer.send("menuEnabler", "unlock")
    }

    static viewStart() {
        Interface.unlock()
        Interface.start.style.display = "inline-block"
        Interface.stop.style.display = "none"
        Interface.progressMode.disabled = true
        Interface.preferences.disabled = false

        ipcRenderer.send("menuEnabler", "viewStart")
    }

    static viewStop() {
        Interface.lock()
        Interface.start.style.display = "none"
        Interface.stop.style.display = "inline-block"
        Interface.progressMode.disabled = false
        Interface.preferences.disabled = true

        ipcRenderer.send("menuEnabler", "viewStop")
    }

    static setProgressBar(value) {
        ipcRenderer.send("setProgressBar", value)
    }
}
