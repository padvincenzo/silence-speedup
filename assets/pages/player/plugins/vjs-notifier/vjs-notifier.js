/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

function notifier(options) {
    const dom = document.createElement("div");
    dom.classList.add("vjs-notice");
    this.el().appendChild(dom);

    const defaultTimeout = options.defaultTimeout ?? 1500;
    var noticeTimeout = null;

    this.notify = (notice, timeout) => {
        if (noticeTimeout != null) {
            clearTimeout(noticeTimeout)
        }

        dom.innerHTML = notice;
        dom.style.display = "inline-block";

        noticeTimeout = setTimeout(() => {
            dom.style.display = "none";
            dom.innerText = "";
        }, timeout ?? defaultTimeout);
    };
}

videojs.registerPlugin("notifier", notifier);
