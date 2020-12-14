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
    let platform = os.platform()
    let ffpath = null

    // Using static binaries
    switch (platform) {
      case "darwin": {
        // https://evermeet.cx/ffmpeg/
        ffpath = path.join(__dirname, "..", "ffmpeg", "ffmpeg")
        break
      }
      case "win32": {
        // https://www.gyan.dev/ffmpeg/builds/
        ffpath = path.join(__dirname, "..", "ffmpeg", "bin", "ffmpeg.exe")
        break
      }
      case "linux": {
        // https://www.johnvansickle.com/ffmpeg/
        ffpath = path.join(__dirname, "..", "ffmpeg", "ffmpeg")
        break
      }
    }

    if(ffpath == null || ! fs.existsSync(ffpath)) {
      Settings.lock()
      log("FFmpeg binaries not found.")
    } else {
      FFmpeg.command = ffpath
    }
    // If you have FFmpeg installed on your computer and
    // you want to use it instead, then just comment
    // this block above and set the static variable
    // FFmpeg.command to the path of your ffmpeg executable.
    //
    // Note: you can as well use a command that call ffmpeg,
    // e.g. on linux type:
    //
    //            FFmpeg.command = "ffmpeg"
    //
    // and should be fine.

    FFmpeg.progressBar = document.getElementById("ffmpegProgressBar")
    FFmpeg.progress = document.getElementById("ffmpegProgress")
    FFmpeg.time = document.getElementById("ffmpegProgressTime")
    FFmpeg.speed = document.getElementById("ffmpegProgressSpeed")
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

module.exports = FFmpeg
