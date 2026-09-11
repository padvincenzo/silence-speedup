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
    #demoBtn = null;

    #silenceTS = { start: [], end: [] };

    constructor(url, name, extension) {
        this.#url = url;
        this.#name = name;
        this.#outputName = name;
        this.#extension = extension;
        this.#outputExtension = extension;

        this.#ref = document.createElement("tr");

        var text = document.createElement("td");
        text.innerText = this.#name;
        text.setAttribute("title", url);
        text.classList.add("text-start");
        this.#ref.appendChild(text);

        this.#status = document.createElement("td");
        this.#status.innerHTML = "<div class='spinner-border spinner-border-sm' role='status'><span class='visually-hidden'>" + t("status.loading") + "</span></div>";
        this.#status.classList.add("text-start");
        this.#ref.appendChild(this.#status);

        var actions = document.createElement("td");

        this.#removeBtn = document.createElement("button");
        this.#removeBtn.setAttribute("class", "btn btn-outline-danger btn-sm me-1");
        this.#removeBtn.innerHTML = "<i class='fa fa-trash'></i>";
        this.#removeBtn.title = t("file.remove");
        this.#removeBtn.addEventListener("click", (event) => {
            EntryList.remove(this.#name);
        });
        actions.appendChild(this.#removeBtn);

        this.#demoBtn = document.createElement("button");
        this.#demoBtn.setAttribute("class", "btn btn-outline-success btn-sm me-1");
        this.#demoBtn.innerHTML = "<i class='fa fa-headphones'></i>";
        this.#demoBtn.title = t("file.demo");
        this.#demoBtn.addEventListener("click", (event) => {
            SpeedUp.start([this], true).then(() => {
                let silences = this.#silenceTS.start.map((start, i) => {
                    return {
                        t_start: start,
                        t_end: this.#silenceTS.end[i],
                    };
                });
                ipcRenderer.send(
                    "demo",
                    {
                        filepath: this.#url,
                        filename: this.#name,
                        silences: silences,
                        setting: {
                            silenceMargin: SpeedUp.silenceMargin,
                            silenceSpeed: SpeedUp.silenceSpeed,
                            playbackSpeed: SpeedUp.playbackSpeed
                        }
                    }
                );
            });
        });
        actions.appendChild(this.#demoBtn);

        this.#ref.appendChild(actions);

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
            this.status = t("status.loaded", { duration: "?" });
            return;
        }

        if (this.#duration != null) {
            return;
        }

        this.#duration = duration;
        this.#seconds = FFmpeg.getSecondsFromTime(duration);
        this.status = t("status.loaded", { duration: this.#duration });
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
        this.status = t("status.queued");
        this.#removeBtn.style.display = "none";
        this.#demoBtn.style.display = "none";
        this.#ref.setAttribute("class", "");

        this.#silenceTS = { start: [], end: [] };
    }

    highlight() {
        this.#ref.setAttribute("class", "");
        Shell.log(t("log.started", { name: this.#name }));
        ipcRenderer.send("progressUpdate", "name", this.#name);
    }

    gotError(err) {
        this.#ref.setAttribute("class", "bg-warning text-dark");
        this.#status.innerHTML = err;
        this.#removeBtn.style.display = "inline-block";
        this.#demoBtn.style.display = "inline-block";
    }

    /**
     * Records one silence boundary, trimmed by the margin.
     *
     * The margin moves a start later and an end earlier, so that a little
     * audio is kept on each side of the silence and words are not clipped.
     * It applies to every boundary: this used to skip the first entry of each
     * list, and since starts[0] and ends[0] belong to the same silence, the
     * first pause in every file came out a margin too wide at both ends.
     */
    appendTS(i, ts, offset) {
        let shift = parseFloat(offset) * ((i == "start") ? 1 : -1);
        let value = parseFloat(ts) + shift;

        // The margin must never push a boundary outside the media.
        if (!(value > 0)) {
            value = 0;
        }
        if (this.#seconds != null && value > this.#seconds) {
            value = this.#seconds;
        }

        this.#silenceTS[i].push(value.toFixed(7));
    }

    /**
     * Closes a silence that runs to the end of the file.
     *
     * A final silence_start with no matching silence_end used to fail the
     * whole file as a data error. Current FFmpeg closes the last silence at
     * EOF on its own, so this is a guard rather than an everyday path, but
     * the end of the media is the answer whenever it is not.
     */
    closeTrailingSilence(offset) {
        if (this.#silenceTS.start.length != this.#silenceTS.end.length + 1) {
            return false;
        }
        if (this.#seconds == null) {
            return false;
        }

        this.appendTS("end", this.#seconds, offset);
        return true;
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
        this.#ref.setAttribute("class", "bg-success text-light");
        this.status = t("status.completed");
        Shell.success(t("log.completed", { name: this.#outputName }));
        this.#removeBtn.style.display = "inline-block";
        this.#demoBtn.style.display = "inline-block";
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
