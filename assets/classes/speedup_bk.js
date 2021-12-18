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

module.exports = class SpeedUp {
  static stream = null
  static interrupted = true
  static currentEntry = null

  static threshold
  static silenceMinimumDuration
  static silenceMargin
  static dropAudio
  static muteAudio
  static silenceSpeed
  static playbackSpeed
  static videoExtension

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
    playback: {
      options: [
        "-hide_banner",
        "-loglevel", "warning",
        "-stats",
        "-ss", null,                        // Start time
        "-to", null,                        // End time
        "-i", null                          // Input file
      ],
      index: 10                             // Index for output file
    },
    silence: {
      options: [
        "-hide_banner",
        "-loglevel", "warning",
        "-stats",
        "-ss", null,                        // Start time
        "-to", null,                        // End time
        "-i", null                          // Input file
      ],
      index: 10                             // Index for output file
    },
    copy: {
      options: [
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

  static concatOptions = [
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
    SpeedUp.threshold = Config.data.thresholds[Interface.threshold.value].value
    SpeedUp.silenceMinimumDuration = parseFloat(Interface.silenceMinimumDuration.value)
    SpeedUp.silenceMargin = parseFloat(Interface.silenceMargin.value)
    SpeedUp.silenceSpeed = Config.data.speeds[Interface.silenceSpeed.value].text
    SpeedUp.dropAudio = (SpeedUp.silenceSpeed == "remove")
    SpeedUp.muteAudio = (SpeedUp.dropAudio ? false : muteAudio.checked)
    SpeedUp.playbackSpeed = Config.data.speeds[Interface.playbackSpeed.value].text
    SpeedUp.videoExtension = Interface.videoExtension.value

    SpeedUp.silenceDetectOptions[7] = "silencedetect=n=" + SpeedUp.threshold + ":d=" + (SpeedUp.silenceMinimumDuration + 2 * SpeedUp.silenceMargin)
    SpeedUp.concatOptions[9] = Config.fragmentListPath
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
        let videoFilter = Config.data.speeds[Interface.silenceSpeed.value].video
        let audioFilter = SpeedUp.muteAudio ? "[0:a]volume=enable=0[a]" : Config.data.speeds[Interface.silenceSpeed.value].audio
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
      let videoFilter = Config.data.speeds[Interface.playbackSpeed.value].video
      let audioFilter = Config.data.speeds[Interface.playbackSpeed.value].audio
      SpeedUp.exportOptions.playback.options[10] = "-filter_complex"
      SpeedUp.exportOptions.playback.options[11] = videoFilter + audioFilter
      SpeedUp.exportOptions.playback.options[12] = "-map"
      SpeedUp.exportOptions.playback.options[13] = "[v]"
      SpeedUp.exportOptions.playback.options[14] = "-map"
      SpeedUp.exportOptions.playback.options[15] = "[a]"
      SpeedUp.exportOptions.playback.index = 16
    }
  }

  static async start() {
    SpeedUp.interrupted = false
    Interface.viewStop()

    SpeedUp.setOptions()
    SpeedUp.setFilters()

    var entries = EntryList.values
    var len = entries.length

    if(len == 0) {
      Shell.log("No video queued.")
      Interface.viewStart()
      return
    }

    ipcRenderer.send("progressUpdate", "total", len)

    for(let i = 0; i < len; i++)
      entries[i].prepare()

    for(let i = 0; i < len && !SpeedUp.interrupted; i++) {
      let entry = entries[i]
      SpeedUp.currentEntry = entry // Only for interrupt

      if(SpeedUp.videoExtension != "keep")
        entry.changeExtension(SpeedUp.videoExtension)

      Interface.setProgressBar(i / len)
      ipcRenderer.send("progressUpdate", "completed", i)

      await SpeedUp.process(entries[i])

      SpeedUp.currentEntry = null
    }

    if(SpeedUp.interrupted) return
    SpeedUp.end()
  }

  static async process(entry) {
    let error = false
    entry.highlight()

    error = await SpeedUp.silenceDetect(entry)
    if(SpeedUp.interrupted || error) return
    error = await SpeedUp.exportFragments(entry)
    if(SpeedUp.interrupted || error) return
    error = await SpeedUp.concatFragments(entry)
    if(SpeedUp.interrupted || error) return

    entry.finished()
  }

  static interrupt() {

    Shell.err("Stopping...")
    SpeedUp.interrupted = true
    FFmpeg.interrupt()

    if(SpeedUp.currentEntry != null) {
      SpeedUp.currentEntry.gotError("Interrupted")
      SpeedUp.currentEntry = null
    }

    ipcRenderer.send("progressUpdate", "name", "")
    ipcRenderer.send("progressUpdate", "status", "Interrupted")

    Interface.viewStart()
  }

  static end() {
    Shell.log("All done.")
    FFmpeg.update(null)

    ipcRenderer.send("progressUpdate", "name", "")

    Interface.viewStart()
  }

  static reportError(msg, entry) {
    entry.gotError("Failed")
    Shell.err(msg)
  }

  static async silenceDetect(entry) {
    if(SpeedUp.interrupted) return

    entry.status = "Detecting silences..."
    Shell.log("Detecting silences...")

    SpeedUp.silenceDetectOptions[5] = entry.url

    return await FFmpeg.run(SpeedUp.silenceDetectOptions, {entry: entry},
      (str, data) => {
        let res = null

        while((res = SpeedUp.silenceRegExp.exec(str)) != null)
          data.entry.appendTS(res[1], parseFloat(res[2]).toFixed(3), SpeedUp.silenceMargin)
      },
      (data) => {
        if(data.entry.tsCheck()) {
          if(data.entry.hasSilences())
            Shell.log(`${data.entry.silencePercentage()} % of the video detected as silence.`)
          else
            Shell.log("No silences detected, moving on to the next.")
          return
        }

        SpeedUp.reportError("Data error: indexes do not match.", data.entry)
      },
      (data) => {
        SpeedUp.reportError("Sorry, no fragments found. Moving on to the next.", data.entry)
      })
  }

  static async exportFragments(entry) {
    if(SpeedUp.interrupted) return true

    SpeedUp.exportOptions.playback.options[9] = entry.url
    SpeedUp.exportOptions.silence.options[9] = entry.url

    entry.status = "Exporting..."
    Shell.log("Exporting...")

    SpeedUp.videoExtension = Interface.videoExtension.value == "keep" ? entry.extension : Interface.videoExtension.value
    SpeedUp.stream = fs.createWriteStream(Config.fragmentListPath, {flags:'w'})

    let sf = entry.silenceTS
    let n = sf.start.length - 1
    let c = 0
    let i = 0
    let error = false

    var counter = {
      count: 0,
      name: function (extension) {
        let number = this.count.toString().padStart(6, "0")
        this.count += 1
        let name = `f_${number}.${extension}`
        let fragmentPath = path.join(Config.tmpPath, name)
        if(fs.existsSync(fragmentPath))
          fs.unlinkSync(fragmentPath)
        SpeedUp.stream.write(`file '${fragmentPath}'\n`)
        return fragmentPath
      }
    }

    if(sf.start[0] != "0.00") {
      error = await SpeedUp.exportPlaybackFragment(entry, "0.00", sf.start[0], counter)
      if(error) return error
    }

    for(i = 0; i < n && !SpeedUp.interrupted; i++) {
      error = await SpeedUp.exportSilenceFragment(entry, sf.start[i], sf.end[i], counter)
      if(error) return error
      error = await SpeedUp.exportPlaybackFragment(entry, sf.end[i], sf.start[i+1], counter)
      if(error) return error
    }

    error = await SpeedUp.exportSilenceFragment(entry, sf.start[i], sf.end[i], counter)
    if(error) return error

    if(sf.end[i] < entry.seconds) {
      error = await SpeedUp.exportPlaybackFragment(entry, sf.end[i], entry.seconds, counter)
      if(error) return error
    }

    return error
  }

  static async exportSilenceFragment(entry, startTS, endTS, counter) {
    if(SpeedUp.interrupted) return true

    if(SpeedUp.dropAudio)
      return false

    if(parseFloat(endTS) - parseFloat(startTS) <= 0.002)
      return false

    SpeedUp.exportOptions.silence.options[5] = startTS
    SpeedUp.exportOptions.silence.options[7] = endTS
    let output = counter.name(entry.outputExtension)
    SpeedUp.exportOptions.silence.options[SpeedUp.exportOptions.silence.index] = output

    let error = await FFmpeg.run(SpeedUp.exportOptions.silence.options, {entry: entry, startTS: startTS, endTS: endTS}, null, null, (data) => {
      Shell.warn(`Fragment [${data.startTS} - ${data.endTS} got filtering error, trying to copy.`)
    })

    if(error && !SpeedUp.interrupted)
      error = await SpeedUp.copyFragment(entry, startTS, endTS, output)

    return error
  }

  static async exportPlaybackFragment(entry, startTS, endTS, counter) {
    if(SpeedUp.interrupted) return true

    if(parseFloat(endTS) - parseFloat(startTS) <= 0.002)
      return false

    SpeedUp.exportOptions.playback.options[5] = startTS
    SpeedUp.exportOptions.playback.options[7] = endTS
    let output = counter.name(entry.outputExtension)
    SpeedUp.exportOptions.playback.options[SpeedUp.exportOptions.playback.index] = output

    let error = await FFmpeg.run(SpeedUp.exportOptions.playback.options, {entry: entry, startTS: startTS, endTS: endTS}, null, null, (data) => {
      Shell.warn(`Fragment [${data.startTS} - ${data.endTS} got filtering error, trying to copy.`)
    })

    if(error && !SpeedUp.interrupted)
      error = await SpeedUp.copyFragment(entry, startTS, endTS, output)

    return error
  }

  static async copyFragment(entry, startTS, endTS, name) {
    if(SpeedUp.interrupted) return true

    SpeedUp.exportOptions.copy.options[5] = startTS
    SpeedUp.exportOptions.copy.options[7] = endTS
    SpeedUp.exportOptions.copy.options[9] = entry.url
    SpeedUp.exportOptions.copy.options[12] = name

    return await FFmpeg.run(SpeedUp.exportOptions.copy.options, {entry: entry, startTS: startTS, endTS: endTS}, null, (data) => {
      Shell.log("Fragment copied succesfully")
    },
    (data) => {
      SpeedUp.reportError(`Error while copying fragment [${data.startTS} - ${data.endTS}]`, data.entry)
    })
  }

  static async concatFragments(entry) {
    if(SpeedUp.stream != null) {
      SpeedUp.stream.end()
      SpeedUp.stream = null
    }

    if(SpeedUp.interrupted) return true

    entry.status = "Concatenating..."
    Shell.log("Concatenating...")

    SpeedUp.concatOptions[16] = path.join(Config.data.exportPath, entry.outputName)

    return await FFmpeg.run(SpeedUp.concatOptions, {entry: entry}, null, null, (data) => {
      SpeedUp.reportError("Error during concatenation.", data.entry)
    })
  }

}
