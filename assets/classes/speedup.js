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

    if(SpeedUp.interrupted) {
      entries[i].gotError("Interrupted")
      return
    }

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
    if(SpeedUp.interrupted) {
      entries[i].gotError("Interrupted")
      return
    }

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
        if(SpeedUp.interrupted)
          entries[i].gotError("Interrupted")
        else
          SpeedUp.reportError("Sorry, no fragments found. Moving on to the next.", code, entries, i, len)
      }
    })
  }

  static exportFragments(entries, i, len, silenceFragments) {
    if(SpeedUp.interrupted) {
      entries[i].gotError("Interrupted")
      return
    }

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
    if(SpeedUp.interrupted) {
      entries[i].gotError("Interrupted")
      return
    }

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
          if(SpeedUp.interrupted)
            entries[i].gotError("Interrupted")
          else
            SpeedUp.exportCopiedFragment(startTime, endTime, output, "playback", entries, i, len, silenceFragments, j, n, c + 1)
        }
      })
    }
  }

  static exportPlaybackFragment(entries, i, len, silenceFragments, j, n, c) {
    if(SpeedUp.interrupted) {
      entries[i].gotError("Interrupted")
      return
    }

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
        if(SpeedUp.interrupted)
          entries[i].gotError("Interrupted")
        else
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
        if(SpeedUp.interrupted)
          entries[i].gotError("Interrupted")
        else
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
        if(SpeedUp.interrupted)
          entries[i].gotError("Interrupted")
        else
          SpeedUp.reportError("Non sono riuscito a unire i frammenti. Passo al prossimo video.", code, entries, i, len)
      }
    })
  }

}

module.exports = SpeedUp
