const electron = require("electron");
const ipc = electron.ipcRenderer;
const shell = electron.shell;
const currentWebContents = electron.remote.getCurrentWebContents();
const fs = require("fs");
const path = require("path");
const os = require("os");
const spawn = require("child_process").spawn;
const spawnSync = require("child_process").spawnSync;


const defaultPath = path.join(os.homedir(), 'Documenti', 'speededup');
var exportPath = defaultPath;
var tmpPath = path.join(exportPath, "tmp");
var fragmentListPath = path.join(exportPath, "list.txt");

function log(msg) {
  Settings.shell.innerHTML += msg + "\n";
  Settings.shell.scrollTop = Settings.shell.scrollHeight;
}

class EntryList {
  static list = {};
  static canImport = true;

  static import(urls) {
    if(urls == undefined || urls == null)
      return 0;

    if(! EntryList.canImport)
      return 0;

    let len = urls.length;
    if(len == 0)
      return 0;

    let c = 0;

    for(var i = 0; i < len; i++) {
      let url = urls[i].toString();
      let name = Entry.getNameFromUrl(url);
      let extension = Entry.getExtensionFromName(name);
      if(Entry.isExtensionValid(extension)) {
        if(EntryList.list.hasOwnProperty(name)) {
          log("Non posso aggiungere il file " + name + ", il suo nome è già presente in lista.");
        } else {
          var entry = new Entry(url, name, extension);
          EntryList.list[name] = entry;
          c++;
        }
      }
    }

    return c;
  }

  static remove(name) {
    var entry = EntryList.list[name];
    Settings.entryList.removeChild(entry.ref);
    log("File " + entry.name + " rimosso.");
    delete EntryList.list[name];
  }

  static get values() {
    return Object.values(EntryList.list);
  }
}

class Entry {
  #url = null;
  #name = null;
  #outputName = null;
  #extension = null;
  #duration = null;
  #seconds = null;
  #ref = null;
  #progress = null;
  #removeBtn = null;

  constructor(url, name, extension) {
    this.#url = url;
    this.#name = name;
    this.#outputName = name;
    this.#extension = extension;

    this.#ref = document.createElement("div");
    this.#ref.setAttribute("class", "entry");
    this.#ref.setAttribute("title", url);

    var text = document.createElement("div");
    text.setAttribute("class", "entryName");
    text.appendChild(document.createTextNode(this.#name));
    this.#ref.appendChild(text);

    this.#progress = document.createElement("div");
    this.#progress.setAttribute("class", "progress");
    this.#progress.innerHTML = "Caricamento...";
    this.#ref.appendChild(this.#progress);

    this.#removeBtn = document.createElement("div");
    this.#removeBtn.setAttribute("class", "remove");
    this.#removeBtn.appendChild(document.createTextNode("×"));
    this.#removeBtn.addEventListener("click", (event) => {
      EntryList.remove(this.#name);
    });
    this.#ref.appendChild(this.#removeBtn);

    FFmpeg.getVideoDuration(this);

    Settings.entryList.appendChild(this.#ref);
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
    let lastDot = name.lastIndexOf(".");
    this.#outputName = this.#name.substring(0, lastDot) + newExtension;
  }

  get outputName() {
    return this.#outputName;
  }

  set duration(duration) {
    if(duration == null) {
      this.status = "In attesa";
      return;
    }

    if(this.#duration != null)
      return;

    this.#duration = duration;
    this.#seconds = FFmpeg.getSecondsFromTime(duration);
    this.status = "In attesa [" + this.#duration + "]";
  }

  get duration() {
    return this.#duration;
  }

  get seconds() {
    return this.#seconds;
  }

  set status(status) {
    this.#progress.innerHTML = status;
    ipc.send("changeStatus", status);
  }

  gotError(err) {
    this.#progress.innerHTML = err;
    this.#ref.style.backgroundColor = "var(--c-5)";
  }

  set highlight(highlight) {
    if(highlight) {
      this.#ref.style.backgroundColor = "var(--c-1)";
  	  this.#ref.style.color = "var(--c-light)";
      log("Inizio a lavorare su " + this.#name + ".");
      ipc.send("changeName", this.#name);
    } else {
      this.#ref.style.backgroundColor = "var(--c-3)";
  	  this.#ref.style.color = "var(--c-light)";
      log(this.#outputName + " è pronto.");
      this.status = "Video pronto!";
    }
  }

  getReady() {
    this.status = "In coda";
    this.#removeBtn.style.display = "none";
    this.#ref.style.backgroundColor = "initial";
    this.#ref.style.color = "var(--c-dark)";
  }

  static getNameFromUrl(url) {
    var lastSlash = url.lastIndexOf("/");
    var lastBackSlash = url.lastIndexOf("\\");
    return url.substr(Math.max(lastSlash, lastBackSlash) + 1);
  }

  static getExtensionFromName(name) {
    var lastDot = name.lastIndexOf(".");
    if(lastDot < 1)
      return false;

    return name.substr(lastDot + 1);
  }

  static isExtensionValid(extension) {
    return /avi|mkv|mp4/.test(extension);
  }
}

class ProcessVideo {
  static spawn = null;
  static stream = null;
  static stop = false;

  static autoDetectThreshold = false;
  static threshold = 0.02;
  static silenceMinimumDuration = 0.3;
  static silenceMargin = 0.1;
  static dropAudio = false;
  static muteAudio = false;
  static silenceSpeed = 8;
  static soundSpeed = 1;
  static videoExtension = "mp4";

  static volumeDetectOptions = [
    "-hide_banner",
    "-i", null,                             // Input file
    "-af", "volumedetect",
    "-f", "null",
    "-"
  ];

  static silenceDetectOptions = [
    "-hide_banner",
    "-ss", "0.00",
    "-i", null,                             // Input file
    "-af", null,                            // silencedetect filter
    "-f", "null",
    "-"
  ];

  static exportOptions = {
    "sound": {
      "options": [
        "-hide_banner",
        "-loglevel", "warning",
        "-stats",
        "-ss", null,                        // Start time
        "-to", null,                        // End time
        "-i", null                          // Input file
      ],
      "index": 10
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
      "index": 10
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
  ];

  static avgRegExp = new RegExp(/mean_volume: (-?\d+(.\d+)?) dB/);
  static silenceRegExp = new RegExp(/silence_(start|end): (-?\d+(.\d+)?)/, "gm");

  static setOptions() {
    ProcessVideo.autoDetectThreshold = (Settings.threshold.value == 0);
    ProcessVideo.threshold = (ProcessVideo.autoDetectThreshold ? null : Settings.thresholds[Settings.threshold.value].value);
    ProcessVideo.silenceMinimumDuration = parseFloat(Settings.silenceMinimumDuration.value);
    ProcessVideo.silenceMargin = parseFloat(Settings.silenceMargin.value);
    ProcessVideo.silenceSpeed = Settings.speed[Settings.silenceSpeed.value].text;
    ProcessVideo.dropAudio = (ProcessVideo.silenceSpeed == "Rimuovi");
    ProcessVideo.muteAudio = (ProcessVideo.dropAudio ? false : muteAudio.checked);
    ProcessVideo.soundSpeed = Settings.speed[Settings.soundSpeed.value].text;
    ProcessVideo.videoExtension = Settings.videoExtension.value;

    ProcessVideo.mergeOptions[9] = fragmentListPath;

    ProcessVideo.updateTreshold();
  }

  static setFilters() {

    if(! ProcessVideo.dropAudio) {

      ProcessVideo.exportOptions.silence.options.splice(10, 7);
      ProcessVideo.exportOptions.silence.index = 10;

      if(ProcessVideo.silenceSpeed == "1x") {
        if(ProcessVideo.muteAudio) {
          ProcessVideo.exportOptions.silence.options[10] = "-af";
          ProcessVideo.exportOptions.silence.options[11] = "volume=enable=0";
          ProcessVideo.exportOptions.silence.index = 12;
        }
      } else {
        let videoFilter = Settings.speed[Settings.silenceSpeed.value].video;
        let audioFilter = Settings.speed[Settings.silenceSpeed.value].audio;
        if(ProcessVideo.muteAudio)
          audioFilter.replace("[a]", ", volume=enable=0[a]");
        ProcessVideo.exportOptions.silence.options[10] = "-filter_complex";
        ProcessVideo.exportOptions.silence.options[11] = videoFilter + audioFilter;
        ProcessVideo.exportOptions.silence.options[12] = "-map";
        ProcessVideo.exportOptions.silence.options[13] = "[v]";
        ProcessVideo.exportOptions.silence.options[14] = "-map";
        ProcessVideo.exportOptions.silence.options[15] = "[a]";
        ProcessVideo.exportOptions.silence.index = 16;
      }
    }

    ProcessVideo.exportOptions.sound.options.splice(10, 7);
    ProcessVideo.exportOptions.sound.index = 10;

    if(ProcessVideo.soundSpeed != "1x") {
      let videoFilter = Settings.speed[Settings.soundSpeed.value].video;
      let audioFilter = Settings.speed[Settings.soundSpeed.value].audio;
      ProcessVideo.exportOptions.sound.options[10] = "-filter_complex";
      ProcessVideo.exportOptions.sound.options[11] = videoFilter + audioFilter;
      ProcessVideo.exportOptions.sound.options[12] = "-map";
      ProcessVideo.exportOptions.sound.options[13] = "[v]";
      ProcessVideo.exportOptions.sound.options[14] = "-map";
      ProcessVideo.exportOptions.sound.options[15] = "[a]";
      ProcessVideo.exportOptions.sound.index = 16;
    }
  }

  static updateTreshold() {
    ProcessVideo.silenceDetectOptions[6] = "silencedetect=n=" + ProcessVideo.threshold + ":d=" + (ProcessVideo.silenceMinimumDuration + 2 * ProcessVideo.silenceMargin);
  }

  static printData(data) {
    console.log(data);
  }

  static start(entries) {
    ProcessVideo.stop = false;
    ProcessVideo.setOptions();
    ProcessVideo.setFilters();

    var len = entries.length;

    if(len == 0) {
      log("Nessun video da processare.");
      Settings.viewStart();
      return;
    }

    for(var i = 0; i < len; i++)
      entries[i].getReady();

    ipc.send("changeTotal", len);

    ProcessVideo.init(entries, 0, len);
  }

  static interrupt(msg = null) {
    ProcessVideo.stop = true;

    if(msg == null) {
      ProcessVideo.spawn.stdin.write("q");
      log("Interruzione...");
      ipc.send("changeName", "");
    } else {
      log(msg);
    }

    Settings.viewStart();
  }

  static end() {
    log("Ho finito di elaborare tutti i video.");
    FFmpeg.update(null);

    ipc.send("changeName", "");

    Settings.viewStart();
  }

  static reportError(msg, code, entries, i, len) {
    entries[i].gotError("Fallito [" + code + "]");
    log(msg);
    ProcessVideo.init(entries, i + 1, len);
  }

  static init(entries, i, len) {
    Settings.setProgressBar(i / len);

    ipc.send("changeCompleted", i);

    if(i == len) {
      ProcessVideo.end();
      return;
    }

    if(ProcessVideo.stop)
      return;

    entries[i].highlight = true;

    let url = entries[i].url;
    ProcessVideo.volumeDetectOptions[2] = url;
    ProcessVideo.silenceDetectOptions[4] = url;
    ProcessVideo.exportOptions.sound.options[9] = url;
    ProcessVideo.exportOptions.silence.options[9] = url;
    ProcessVideo.exportOptions.copy.options[9] = url;
    ProcessVideo.mergeOptions[16] = path.join(exportPath, entries[i].outputName);

    ProcessVideo.volumeDetect(entries, i, len);
  }

  static volumeDetect(entries, i, len) {
    if(ProcessVideo.stop)
      return;

    if(! ProcessVideo.autoDetectThreshold) {
      ProcessVideo.silenceDetect(entries, i, len);
      return;
    }

    ProcessVideo.threshold = null;

    entries[i].status = "Valutando la soglia...";

    // log(ProcessVideo.volumeDetectOptions);
    ProcessVideo.spawn = spawn(FFmpeg.command, ProcessVideo.volumeDetectOptions);

    ProcessVideo.spawn.stdout.on("data", ProcessVideo.printData);

    ProcessVideo.spawn.stderr.on("data", (err) => {
      let str = err.toString();

      if(! FFmpeg.update(str, entries[i].seconds)) {
        var avg = ProcessVideo.avgRegExp.exec(str);
        if(avg != null)
          ProcessVideo.threshold = parseFloat(avg[1]) - 5.0;
        else
          FFmpeg.mayLog(str);
      }
    });

    ProcessVideo.spawn.on("exit", (code) => {
      if(code == 0) {

        if(ProcessVideo.threshold != null) {
          log("Soglia trovata: " + ProcessVideo.threshold + " dB");
          ProcessVideo.updateTreshold();
          ProcessVideo.silenceDetect(entries, i, len);
        } else {
          log("Non sono riuscito a trovare la soglia. Passo al prossimo video.");
          entries[i].gotError("Soglia non trovata");
          ProcessVideo.init(entries, i + 1, len);
        }

      } else ProcessVideo.reportError("Non sono riuscito a trovare la soglia. Passo al prossimo video.", code, entries, i, len);
    });
  }

  static silenceDetect(entries, i, len) {
    if(ProcessVideo.stop)
      return;

    entries[i].status = "Cercando i frammenti...";

    // log(ProcessVideo.silenceDetectOptions);
    ProcessVideo.spawn = spawn(FFmpeg.command, ProcessVideo.silenceDetectOptions);

    var silenceFragments = [];
  	var seconds = 0.0;
    var startIndex = 0;
    var endIndex = 0;

    ProcessVideo.spawn.stdout.on("data", ProcessVideo.printData);

    ProcessVideo.spawn.stderr.on("data", (err) => {
      var str = err.toString();
      var hasCaptured = false;
      var res = null;

      while((res = ProcessVideo.silenceRegExp.exec(str)) != null) {
        hasCaptured = true;
        switch (res[1]) {
          case "start": {
            let startTime = parseFloat(res[2]) + (startIndex == 0 ? 0 : ProcessVideo.silenceMargin);
            if(startIndex >= endIndex)
              silenceFragments.push([startTime, null]);
            else {
              silenceFragments[startIndex][0] = startTime;
              seconds += silenceFragments[startIndex][1] - startTime;
            }
            startIndex += 1;
            break;
          }
          case "end": {
            let endTime = parseFloat(res[2]) - ProcessVideo.silenceMargin;
            if(endIndex >= startIndex)
              silenceFragments.push([null, endTime]);
            else {
              silenceFragments[endIndex][1] = endTime;
              seconds += endTime - silenceFragments[endIndex][0];
            }
            endIndex += 1;
            break;
          }
          default: {
            log("Mmh... frammento sconosciuto.");
          }
        }
      }

      if(! hasCaptured) {
        if(! FFmpeg.update(str, entries[i].seconds))
          FFmpeg.mayLog(str);
      }
    });

    ProcessVideo.spawn.on("exit", (code) => {
      if(code == 0) {
        if(startIndex == endIndex) {
          log("Ho riconosciuto il " + (seconds / entries[i].seconds * 100).toFixed(2) + "% del video come silenzio.");
          ProcessVideo.exportFragments(entries, i, len, silenceFragments);
        } else {
          ProcessVideo.reportError("Errore nei dati: gli indici non coincidono.", code, entries, i, len);
        }
      } else ProcessVideo.reportError("Non sono riuscito a trovare i frammenti di silenzio. Passo al prossimo video.", code, entries, i, len);
    });
  }

  static exportFragments(entries, i, len, silenceFragments) {
    if(ProcessVideo.stop)
      return;

    log("Esporto i frammenti...")

    entries[i].status = "Esportando i frammenti...";

    ProcessVideo.videoExtension = Settings.videoExtension.value == "keep" ? entries[i].extension : Settings.videoExtension.value;
    if(fs.existsSync(fragmentListPath))
      fs.unlinkSync(fragmentListPath);
    ProcessVideo.stream = fs.createWriteStream(fragmentListPath, {flags:'a'});

    let n = silenceFragments.length;
    ProcessVideo.exportSoundFragment(entries, i, len, silenceFragments, -1, n, 0);
  }

  static isSkippable(startTime, endTime) {
    return (parseFloat(endTime) - parseFloat(startTime)) < 0.05;
  }

  static getFragmentName(c) {
    let name = path.join(tmpPath, "f_" + c.toString().padStart(6, "0") + "." + ProcessVideo.videoExtension);
    if(fs.existsSync(name))
      fs.unlinkSync(name);
    ProcessVideo.stream.write("file '" + name + "'\n");
    return name;
  }

  static exportSilenceFragment(entries, i, len, silenceFragments, j, n, c) {
    if(ProcessVideo.stop)
      return;

    if(j == n) {
      ProcessVideo.mergeFragments(entries, i, len, c);
      return;
    }

    let startTime = silenceFragments[j][0].toFixed(2);
    let endTime = silenceFragments[j][1].toFixed(2);

    if(ProcessVideo.dropAudio || ProcessVideo.isSkippable(startTime, endTime)) {

      ProcessVideo.exportSoundFragment(entries, i, len, silenceFragments, j, n, c);

    } else {

      ProcessVideo.exportOptions.silence.options[5] = startTime;
      ProcessVideo.exportOptions.silence.options[7] = endTime;
      let output = ProcessVideo.getFragmentName(c);
      ProcessVideo.exportOptions.silence.options[ProcessVideo.exportOptions.silence.index] = output;

      // log(ProcessVideo.exportOptions.silence.options);
      ProcessVideo.spawn = spawn(FFmpeg.command, ProcessVideo.exportOptions.silence.options);

      ProcessVideo.spawn.stdout.on("data", ProcessVideo.printData);

      ProcessVideo.spawn.stderr.on("data", (err) => {
        let str = err.toString();
        if(! FFmpeg.update(str, entries[i].seconds, startTime))
          FFmpeg.mayLog(str);
      });

      ProcessVideo.spawn.on("exit", (code) => {
        if(code == 0)
          ProcessVideo.exportSoundFragment(entries, i, len, silenceFragments, j, n, c + 1);
        else
          ProcessVideo.exportCopiedFragment(startTime, endTime, output, "sound", entries, i, len, silenceFragments, j, n, c + 1);
      });
    }
  }

  static exportSoundFragment(entries, i, len, silenceFragments, j, n, c) {
    if(ProcessVideo.stop)
      return;

    if(j > n) {
      ProcessVideo.mergeFragments(entries, i, len, c);
      return;
    }

    let startTime;
    let endTime;

    if(j == -1) {
      if(silenceFragments[0][0] > 0) {
        startTime = "0.000";
        endTime = silenceFragments[0][0];
      } else {
        ProcessVideo.exportSilenceFragment(entries, i, len, silenceFragments, 0, n, c);
        return;
      }
    } else {
      startTime = silenceFragments[j][1].toFixed(2);
      endTime = (j == n - 1) ? entries[i].seconds.toFixed(2) : silenceFragments[j + 1][0].toFixed(2);
    }

    if(ProcessVideo.isSkippable(startTime, endTime)) {

      ProcessVideo.exportSilenceFragment(entries, i, len, silenceFragments, j + 1, n, c);

    } else {

      ProcessVideo.exportOptions.sound.options[5] = startTime;
      ProcessVideo.exportOptions.sound.options[7] = endTime;
      let output = ProcessVideo.getFragmentName(c);
      ProcessVideo.exportOptions.sound.options[ProcessVideo.exportOptions.sound.index] = output;

      // log(ProcessVideo.exportOptions.sound.options);
      ProcessVideo.spawn = spawn(FFmpeg.command, ProcessVideo.exportOptions.sound.options);

      ProcessVideo.spawn.stdout.on("data", ProcessVideo.printData);

      ProcessVideo.spawn.stderr.on("data", (err) => {
        let str = err.toString();
        if(! FFmpeg.update(str, entries[i].seconds, startTime))
          FFmpeg.mayLog(str);
      });

      ProcessVideo.spawn.on("exit", (code) => {
        if(code == 0)
          ProcessVideo.exportSilenceFragment(entries, i, len, silenceFragments, j + 1, n, c + 1);
        else
          ProcessVideo.exportCopiedFragment(startTime, endTime, output, "silence", entries, i, len, silenceFragments, j + 1, n, c + 1);
      });
    }
  }

  static exportCopiedFragment(ss, to, out, next, entries, i, len, silenceFragments, j, n, c) {
    log("Il frammento [" + ss + " - " + to + "] non è modificabile, provo a copiarlo.");

    ProcessVideo.exportOptions.copy.options[5] = ss;
    ProcessVideo.exportOptions.copy.options[7] = to;
    ProcessVideo.exportOptions.copy.options[11] = out;

    // log(ProcessVideo.exportOptions.copy.options);
    ProcessVideo.spawn = spawn(FFmpeg.command, ProcessVideo.exportOptions.copy.options);

    ProcessVideo.spawn.stdout.on("data", ProcessVideo.printData);

    ProcessVideo.spawn.stderr.on("data", (err) => {
      let str = err.toString();
      if(! FFmpeg.update(str, entries[i].seconds, ss))
        FFmpeg.mayLog(str);
    });

    ProcessVideo.spawn.on("exit", (code) => {
      if(code == 0) {
        log("Frammento copiato correttamente, continuo.");
        switch (next) {
          case "sound": {
            ProcessVideo.exportSoundFragment(entries, i, len, silenceFragments, j, n, c);
            break;
          }
          case "silence": {
            ProcessVideo.exportSilenceFragment(entries, i, len, silenceFragments, j, n, c);
            break;
          }
          default: {
            // Nothing
          }
        }
      } else {
        ProcessVideo.reportError("Non sono riuscito a copiare il frammento. Passo al prossimo video.", code, entries, i, len);
      }
    });
  }

  static mergeFragments(entries, i, len, c) {
    ProcessVideo.stream.end();

    entries[i].status = "Unendo i frammenti...";

    // log(ProcessVideo.mergeOptions);
    ProcessVideo.spawn = spawn(FFmpeg.command, ProcessVideo.mergeOptions);

    ProcessVideo.spawn.stdout.on("data", ProcessVideo.printData);

    ProcessVideo.spawn.stderr.on("data", (err) => {
      var str = err.toString();
      if(! FFmpeg.update(str, entries[i].seconds))
        FFmpeg.mayLog(str);
    });

    ProcessVideo.spawn.on("exit", (code) => {
      if(code == 0) {
        entries[i].highlight = false;
        ProcessVideo.init(entries, i + 1, len);
      } else ProcessVideo.reportError("Non sono riuscito a unire i frammenti. Passo al prossimo video.", code, entries, i, len);
    });
  }
}

class Settings {
  static entryList;
  static addFiles;
  static addFolder;
  static settings;
  static info;

  static start;
  static stop;
  static minimize;
  static devTools;
  static shell;

  static threshold;
  static thresholdValue;
  static silenceMinimumDuration;
  static silenceMargin;
  static muteAudio;
  static silenceSpeed;
  static silenceSpeedValue;
  static soundSpeed;
  static soundSpeedValue;
  static videoExtension;

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
    {"text":"Rimuovi"}                      // 10
  ];

  static thresholds = [
    {                                       // 0
      "text":"Non so"
    },
    {                                       // 1
      "text":"Bassa",
      "value": "0.002"
    },
    {                                       // 2
      "text":"Media",
      "value": "0.02"
    },
    {                                       // 3
      "text":"Alta",
      "value": "0.1"
    }
  ]

  static load() {
    Settings.entryList = document.getElementById("entryList");
    Settings.entryList.ondragover = () => {
      Settings.entryList.setAttribute("class", "drop");
      return false;
    };

    Settings.entryList.ondragleave = () => {
      Settings.entryList.setAttribute("class", "");
      return false;
    };

    Settings.entryList.ondragend = () => {
      Settings.entryList.setAttribute("class", "");
      return false;
    };

    Settings.entryList.ondrop = (event) => {
      event.preventDefault();
      Settings.entryList.setAttribute("class", "");
      let files = Object.values(event.dataTransfer.files)
      let urls = files.map(file => file.path);

      EntryList.import(urls);

      return false;
    };

    Settings.addFiles = document.getElementById("addFiles");
    Settings.addFiles.addEventListener("click", (event) => {
      ipc.send("selectFiles");
    });

    Settings.addFolder = document.getElementById("addFolder");
    Settings.addFolder.addEventListener("click", (event) => {
      ipc.send("selectFolder");
    });

    Settings.settings = document.getElementById("settings");
    Settings.settings.addEventListener("click", (event) => {
      // to do
    });

    Settings.info = document.getElementById("info");
    Settings.info.addEventListener("click", (event) => {
      ipc.send("showCredits");
    });

    Settings.start = document.getElementById("start");
    Settings.stop = document.getElementById("stop");

    Settings.start.addEventListener("click", (event) => {
      Settings.viewStop();
      ProcessVideo.start(EntryList.values);
    });

    Settings.stop.addEventListener("click", (event) => {
      Settings.viewStart();
      ProcessVideo.interrupt();
    });

    Settings.shell = document.getElementById("shell");

    Settings.minimize = document.getElementById("minimize");
    Settings.minimize.addEventListener("click", (event) => {
      ipc.send("viewProgressWindow");
    })

    Settings.devTools = document.getElementById("devTools");
    Settings.devTools.addEventListener("click", (event) => {
      currentWebContents.toggleDevTools();
    })

    Settings.threshold = document.getElementById("threshold");
    Settings.thresholdValue = document.getElementById("thresholdValue");
    Settings.threshold.addEventListener("input", (event) => {
      Settings.thresholdValue.innerHTML = Settings.thresholds[Settings.threshold.value].text;
    });

    Settings.silenceMinimumDuration = document.getElementById("silenceMinimumDuration");
    Settings.silenceMinimumDurationValue = document.getElementById("silenceMinimumDurationValue");
    Settings.silenceMinimumDuration.addEventListener("input", (event) => {
      Settings.silenceMinimumDurationValue.innerHTML = parseFloat(Settings.silenceMinimumDuration.value).toFixed(2);
    });

    Settings.silenceMargin = document.getElementById("silenceMargin");
    Settings.silenceMarginValue = document.getElementById("silenceMarginValue");
    Settings.silenceMargin.addEventListener("input", (event) => {
      Settings.silenceMarginValue.innerHTML = parseFloat(Settings.silenceMargin.value).toFixed(2);
    });

    Settings.muteAudio = document.getElementById("muteAudio");

    Settings.silenceSpeed = document.getElementById("silenceSpeed");
    Settings.silenceSpeedValue = document.getElementById("silenceSpeedValue");
    Settings.silenceSpeed.addEventListener("input", (event) => {
      Settings.silenceSpeedValue.innerHTML = Settings.speed[Settings.silenceSpeed.value].text;
      Settings.muteAudio.disabled = (Settings.silenceSpeed.value == 10);
    });

    Settings.soundSpeed = document.getElementById("soundSpeed");
    Settings.soundSpeedValue = document.getElementById("soundSpeedValue");
    Settings.soundSpeed.addEventListener("input", (event) => {
      Settings.soundSpeedValue.innerHTML = Settings.speed[Settings.soundSpeed.value].text;
    });

    Settings.videoExtension = document.getElementById("videoExtension");
  }

  static lock() {
    Settings.addFiles.disabled = true;
    Settings.addFolder.disabled = true;
    Settings.minimize.disabled = false;
    Settings.start.disabled = true;
    Settings.stop.disabled = false;

    Settings.threshold.disabled = true;
    Settings.silenceMinimumDuration.disabled = true;
    Settings.silenceMargin.disabled = true;
    Settings.muteAudio.disabled = true;
    Settings.silenceSpeed.disabled = true;
    Settings.soundSpeed.disabled = true;
    Settings.videoExtension.disabled = true;

    EntryList.canImport = false;
  }

  static unlock() {
    Settings.addFiles.disabled = false;
    Settings.addFolder.disabled = false;
    Settings.minimize.disabled = true;
    Settings.start.disabled = false;
    Settings.stop.disabled = true;

    Settings.threshold.disabled = false;
    Settings.silenceMinimumDuration.disabled = false;
    Settings.silenceMargin.disabled = false;
    Settings.muteAudio.disabled = (Settings.silenceSpeed.value == 10);
    Settings.silenceSpeed.disabled = false;
    Settings.soundSpeed.disabled = false;
    Settings.videoExtension.disabled = false;

    EntryList.canImport = true;
  }

  static viewStart() {
    Settings.start.style.display = "inline-block";
    Settings.stop.style.display = "none";
    Settings.unlock();
  }

  static viewStop() {
    Settings.start.style.display = "none";
    Settings.stop.style.display = "inline-block";
    Settings.lock();
  }

  static setProgressBar(value) {
    ipc.send("setProgressBar", value);
  }
}

class FFmpeg {
  static command = "ffmpeg";

  static progressBar;
  static progress;
  static frame;
  static fps;
  static time;
  static speed;

  static progressRegExp = new RegExp(/frame=\s*(\d+)\s*fps=\s*(\d+(\.\d+)?)\s*.*time=\s*(\d+:\d+:\d+\.\d+)\s*.*speed=\s*(\d+(\.\d+)?x)/);
  // static ignoreRegExp = new RegExp(/^(Input|Output|Stream|Metadata|\[|\d|\s)/);
  static durationRegExp = new RegExp(/(^|\s)(\d+:\d+:\d+\.\d+)/);
  static timeRegExp = new RegExp(/(\d+):(\d+):(\d+)\.(\d+)/);
  // static fileExists = new RegExp(/File '(.*)' already exists. Overwrite \?/);

  static load() {
    FFmpeg.progressBar = document.getElementById("ffmpegProgressBar");
    FFmpeg.progress = document.getElementById("ffmpegProgress");
    FFmpeg.frame = document.getElementById("ffmpegProgressFrame");
    FFmpeg.fps = document.getElementById("ffmpegProgressFPS");
    FFmpeg.time = document.getElementById("ffmpegProgressTime");
    FFmpeg.speed = document.getElementById("ffmpegProgressSpeed");

    let test = spawnSync(FFmpeg.command, ["-h"]);
    if(test.error != undefined)
      log("Errore: " + test.error);
  }

  static getSecondsFromTime(time) {
    var res = FFmpeg.timeRegExp.exec(time);
    if(res != null)
      return parseInt(res[1]) * 3600 + parseInt(res[2]) * 60 + parseInt(res[3]) + parseInt(res[4]) / 100;
    return 0;
  }

  static getTimeFromSeconds(seconds) {
    let hours = (Math.floor(seconds / 3600)).toString().padStart(2, "0");
    seconds %= 3600;
    let minutes = (Math.floor(seconds / 60)).toString().padStart(2, "0");
    seconds = (seconds % 60).toFixed(2);
    return hours + ":" + minutes + ":" + seconds;
  }

  static update(str, duration = null, offsetCurrentTime = "0") {
    if(str == null) {
      FFmpeg.frame.innerHTML = "";
      FFmpeg.fps.innerHTML = "";
      FFmpeg.time.innerHTML = "";
      FFmpeg.speed.innerHTML = "";
      return false;
    }

    let progress = FFmpeg.progressRegExp.exec(str);

    if(progress == null)
      return false;

    FFmpeg.frame.innerHTML = progress[1];
    FFmpeg.fps.innerHTML = progress[2];
    let time = (offsetCurrentTime == "0") ? progress[4] : FFmpeg.getTimeFromSeconds(parseFloat(offsetCurrentTime) + FFmpeg.getSecondsFromTime(progress[4]));
    FFmpeg.time.innerHTML = time;
    FFmpeg.speed.innerHTML = progress[5];

    var percentage = ((FFmpeg.getSecondsFromTime(progress[4]) + parseFloat(offsetCurrentTime)) / duration * 100);
    FFmpeg.progressBar.style.width = percentage + "%";
    ipc.send("changeProgressBar", percentage);
    return true;
  }

  static mayLog(str) {
    // if(! FFmpeg.ignoreRegExp.test(str))
      console.log(str);
  }

  static getVideoDuration(entry) {
    var options = [
      "-hide_banner",
      "-t", "0.001",
      "-i", entry.url,
      "-f", "null", "-"
    ];

    var test = spawn(FFmpeg.command, options);

    test.stdout.on("data", ProcessVideo.printData);

    test.stderr.on("data", (err) => {
      let str = err.toString();

      let duration = FFmpeg.durationRegExp.exec(str);
      if(duration != null) {
        entry.duration = duration[2];
      }
    });

    test.on("exit", (code) => {
      if(code != 0 || entry.duration == null) {
        log("Non sono riuscito a scoprire la durata di " + entry.name + ".");
        entry.status = "Errore :/";
      }
    });
  }
}

window.onload = () => {
  Settings.load();
  FFmpeg.load();

  if (!fs.existsSync(exportPath))
    fs.mkdirSync(exportPath);

  if (!fs.existsSync(tmpPath))
    fs.mkdirSync(tmpPath);

  log("Silence speedup v0.1");
}

ipc.on("selectedFiles", (event, fileNames) => {
  if(fileNames == undefined)
    return;

  c = EntryList.import(fileNames);
  log("File aggiunti: " + c);
});

ipc.on("selectedFolder", (event, folder) => {
  if(folder == undefined)
    return;

  var list = fs.readdirSync(folder[0]);
  urls = list.map(name => path.join(folder[0], name));

  log("File aggiunti: " + EntryList.import(urls));
});