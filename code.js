/**
 * Silence SpeedUp
 * Speed-up your videos speeding-up (or removing) silences, using FFmpeg.
 * This is an electron-based app.
 *
 * Copyright (C) 2025  Vincenzo Padula
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import { ipcRenderer, shell } from "electron";
import { spawn, spawnSync } from "child_process";
import fs from "fs";
import path from "path";
import os from "os";

import Shell from "./assets/classes/shell.js";
import Interface from "./assets/classes/interface.js";
import Config from "./assets/classes/config.js";
import FFmpeg from "./assets/classes/ffmpeg.js";
import EntryList from "./assets/classes/entrylist.js";
import Entry from "./assets/classes/entry.js";
import SpeedUp from "./assets/classes/speedup.js";

window.onload = () => {
    Config.load();
    Shell.load();
    Interface.load();
    FFmpeg.load();
};

ipcRenderer.on("preferencesUpdate", (event, data) => {
    Config.update(data);
    Interface.update();
    FFmpeg.updateCommand();
});
