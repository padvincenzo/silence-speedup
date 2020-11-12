const electron = require("electron");
const ipc = electron.ipcRenderer;
const shell = electron.shell;
const fs = require("fs");
const path = require("path");
const os = require("os");
const spawn = require("child_process").spawn;
const spawnSync = require("child_process").spawnSync;

const DEFAULT_PATH = path.join(os.homedir(), 'Documenti', 'speededup');

const APP_VERSION = "v0.2.1";
