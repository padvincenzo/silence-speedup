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
    this.#progress.innerHTML = "Loading..."
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
    this.#removeBtn.style.display = "inline-block"
  }

  finished() {
    this.#ref.style.backgroundColor = "var(--c-3)"
    this.#ref.style.color = "var(--c-light)"
    this.status = "Completed"
    log(this.#outputName + " completed.")
    this.#removeBtn.style.display = "inline-block"
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

module.exports = Entry
