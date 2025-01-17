/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

module.exports = class Entry {
    #url = null;
    #name = null;
    #outputName = null;
    #extension = null;
    #outputExtension = null;
    #duration = null;
    #seconds = null;
    #ref = null;
    #status = null;
    #removeBtn = null;

    #silenceTS = { start: [], end: [] };

    constructor(url, name, extension) {
        this.#url = url;
        this.#name = name;
        this.#outputName = name;
        this.#extension = extension;
        this.#outputExtension = extension;

        this.#ref = document.createElement("div");
        this.#ref.setAttribute("class", "entry");
        this.#ref.setAttribute("title", url);

        var text = document.createElement("div");
        text.setAttribute("class", "entryName");
        text.appendChild(document.createTextNode(this.#name));
        this.#ref.appendChild(text);

        this.#status = document.createElement("div");
        this.#status.setAttribute("class", "status");
        this.#status.innerHTML = "Loading...";
        this.#ref.appendChild(this.#status);

        this.#removeBtn = document.createElement("div");
        this.#removeBtn.setAttribute("class", "remove");
        this.#removeBtn.appendChild(document.createTextNode("×"));
        this.#removeBtn.addEventListener("click", (event) => {
            EntryList.remove(this.#name);
        });
        this.#ref.appendChild(this.#removeBtn);

        FFmpeg.getVideoDuration(this);

        Interface.entryList.appendChild(this.#ref);
    }

    get ref() {
        return this.#ref;
    }

    get url() {
        return this.#url;
    }

    get name() {
        return this.#name;
    }

    get extension() {
        return this.#extension;
    }

    changeExtension(newExtension) {
        if (newExtension == "keep") {
            this.#outputName = this.#name;
            this.#outputExtension = this.#extension;
            return;
        }

        let lastDot = this.#name.lastIndexOf(".") + 1;
        this.#outputName = this.#name.substring(0, lastDot) + newExtension;
        this.#outputExtension = newExtension;
    }

    get outputName() {
        return this.#outputName;
    }

    get outputExtension() {
        return this.#outputExtension;
    }

    set duration(duration) {
        if (duration == null) {
            this.status = "Loaded";
            return;
        }

        if (this.#duration != null) {
            return;
        }

        this.#duration = duration;
        this.#seconds = FFmpeg.getSecondsFromTime(duration);
        this.status = "Loaded [" + this.#duration + "]";
    }

    get duration() {
        return this.#duration;
    }

    get seconds() {
        return this.#seconds;
    }

    set status(status) {
        this.#status.innerHTML = status;
        ipcRenderer.send("progressUpdate", "status", status);
    }

    prepare() {
        this.status = "Queued";
        this.#removeBtn.style.display = "none";
        this.#ref.setAttribute("class", "entry");

        this.#silenceTS = { start: [], end: [] };
    }

    highlight() {
        this.#ref.setAttribute("class", "entry highlight");
        Shell.log(`Started working on ${this.#name}.`);
        ipcRenderer.send("progressUpdate", "name", this.#name);
    }

    gotError(err) {
        this.#ref.setAttribute("class", "entry error");
        this.#status.innerHTML = err;
        this.#removeBtn.style.display = "inline-block";
    }

    appendTS(i, ts, offset) {
        let len = this.#silenceTS[i].push(ts);
        if (len > 1) {
            offset = parseFloat(offset) * ((i == "start") ? 1 : -1);
            this.#silenceTS[i][len - 1] = (parseFloat(ts) + offset).toFixed(7);
        }
    }

    tsCheck() {
        return this.#silenceTS.start.length == this.#silenceTS.end.length;
    }

    hasSilences() {
        return this.#silenceTS.start.length > 0;
    }

    silenceSeconds() {
        let seconds = 0.0;
        for (let i = 0, len = this.#silenceTS.start.length; i < len; i++) {
            seconds += parseFloat(this.#silenceTS.end[i]) - parseFloat(this.#silenceTS.start[i]);
        }
        return seconds;
    }

    silencePercentage() {
        return (this.silenceSeconds() / this.seconds * 100).toFixed(2);
    }

    get silenceTS() {
        return this.#silenceTS;
    }

    finished() {
        this.#ref.setAttribute("class", "entry finished");
        this.status = "Completed";
        Shell.log(`${this.#outputName} completed.`);
        this.#removeBtn.style.display = "inline-block";
    }

    static getNameFromUrl(url) {
        var lastSlash = url.lastIndexOf("/");
        var lastBackSlash = url.lastIndexOf("\\");
        return url.substr(Math.max(lastSlash, lastBackSlash) + 1);
    }

    static getExtensionFromName(name) {
        var lastDot = name.lastIndexOf(".");
        if (lastDot < 1) {
            return false;
        }

        return name.substr(lastDot + 1);
    }

    static isExtensionValid(extension) {
        return Config.data.formats.map(format => format.value).indexOf(extension) != -1;
    }
};
