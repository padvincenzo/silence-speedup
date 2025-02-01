/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

function silences(options) {
    const skipSilenceBtn = document.createElement("div");
    skipSilenceBtn.classList.add("vjs-skip-silence");
    this.el().appendChild(skipSilenceBtn);

    skipSilenceBtn.addEventListener("click", () => {
        this.skipCurrentSilence();
    });

    const fastRate = (+(options.fastRate ?? 8)).toFixed(1);
    var normalRate = (+(options.normalRate ?? 1)).toFixed(1);

    var timestamps = [];
    var nextEnd = 0;
    var displayRealRemainingTime = options.displayRealRemainingTime ?? true;

    // Set up a custom element that displays the actually remaining time
    const remainingTimeDisplay = document.createElement("span");
    remainingTimeDisplay.classList.add("vjs-remaining-time-display-custom");
    var currentRemainingTimeDisplay;

    // Replace and hide the original remaining time display
    this.ready(() => {
        currentRemainingTimeDisplay = this.el().querySelector(".vjs-remaining-time-display");
        currentRemainingTimeDisplay.parentNode.insertBefore(remainingTimeDisplay, currentRemainingTimeDisplay);
        if (displayRealRemainingTime) {
            currentRemainingTimeDisplay.style.display = "none";
        } else {
            remainingTimeDisplay.style.display = "none";
        }
    });

    this.skipCurrentSilence = () => {
        if (nextEnd != 0) {
            this.currentTime(nextEnd);
            if (options.onSkip) {
                options.onSkip(nextEnd);
            }
        }
    }

    this.on("timeupdate", (e) => {
        if (e.manuallyTriggered) {
            return;
        }

        let currentTime = +this.currentTime();
        let currentSilence = getCurrent(currentTime);

        if (currentSilence != undefined) {
            this.playbackRate(fastRate);
            skipSilenceBtn.style.display = "inline-block";
            nextEnd = currentSilence.t_end;
        } else {
            this.playbackRate(normalRate);
            skipSilenceBtn.style.display = "none";
            nextEnd = 0;
        }

        if (displayRealRemainingTime) {
            // Assuming that silences' timestamp are correct
            let remainingSilences = timestamps.filter((silence) => silence.t_end > currentTime);
            let remainingSilenceSeconds = 0;

            if (remainingSilences.length > 0) {
                // Eventually correct currentSilence
                if (currentTime > remainingSilences[0].t_start) {
                    remainingSilenceSeconds -= currentTime - remainingSilences[0].t_start;
                }

                remainingSilenceSeconds += remainingSilences.reduce((seconds, silence) => seconds + (silence.t_end - silence.t_start), 0);
            }

            let remainingSpokenSeconds = this.duration() - currentTime - remainingSilenceSeconds;
            let realRemainingSeconds = (remainingSpokenSeconds / +normalRate) + (remainingSilenceSeconds / +fastRate);

            remainingTimeDisplay.innerText = secondsToTime(realRemainingSeconds);
        }
    });

    this.shouldDisplayRealRemainingTime = (should) => {
        if (should == undefined) {
            return displayRealRemainingTime;
        }

        should = should == "true" || should === true;
        displayRealRemainingTime = should;

        if (should) {
            remainingTimeDisplay.style.display = "inline";
            currentRemainingTimeDisplay.style.display = "none";
        } else {
            remainingTimeDisplay.style.display = "none";
            currentRemainingTimeDisplay.style.display = "inline";
        }

        return displayRealRemainingTime;
    };

    this.setSilenceTimestamps = (_timestamps, margin) => {
        // Assume that timestamps are in the form of { start: [], end: [] } and in order of time.
        console.log("Margin:", margin);
        for (let i = 0; i < _timestamps.start.length; i++) {
            console.log("Start:", _timestamps.start[i], "End:", _timestamps.end[i]);
            _timestamps.start[i] = +_timestamps.start[i] + (+margin * normalRate * 4);
            _timestamps.end[i] = +_timestamps.end[i] - (+margin * fastRate * 4);
            console.log("Became Start:", _timestamps.start[i], "End:", _timestamps.end[i]);
            if (_timestamps.start[i] > _timestamps.end[i] - margin) {
                continue;
            }
            timestamps.push({
                t_start: _timestamps.start[i],
                t_end: _timestamps.end[i]
            });
        }

        nextEnd = 0;
    };

    this.setNormalRate = (_normalRate) => {
        normalRate = (+_normalRate).toFixed(1);
    };

    this.getNormalRate = () => {
        return normalRate;
    }

    this.getFastRate = () => {
        return fastRate;
    }

    getCurrent = (needle = 0) => {
        if (timestamps == null) {
            return undefined;
        }

        // Silences are in order, so just check for the first silence that comes after the needle
        let current = timestamps.find((silence) => needle <= silence.t_end);
        return (current && current.t_start <= needle) ? current : undefined;
    };

    this.isInSilence = () => {
        return nextEnd != 0;
    };

}

videojs.registerPlugin("silences", silences);
