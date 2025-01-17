/**
 * Silence SpeedUp
 * Speed - up your videos speeding - up(or removing) silences, using FFmpeg.
 * This is an electron - based app.
 *
 * Copyright(C) 2025  Vincenzo Padula
 *
 * This program is free software: you can redistribute it and / or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.If not, see < https://www.gnu.org/licenses/>.
 */

export default class Config {
    static configPath = path.join(__dirname, "..", "..", "config.json");

    static defaultExportPath = path.join(os.homedir(), "speededup");
    static defaultFFmpegPath = path.join(__dirname, "..", "ffmpeg", (os.type() == "Windows_NT" ? "ffmpeg.exe" : "ffmpeg"));
    static tmpPath = path.join(__dirname, "..", "..", "tmp");
    static fragmentListPath = path.join(Config.tmpPath, "list.txt");

    static data = null;

    static load() {
        let json = fs.readFileSync(Config.configPath, { encoding: 'utf-8' });
        Config.data = JSON.parse(json);

        if (Config.data.exportPath == "") {
            Config.data.exportPath = Config.defaultExportPath;
        }

        if (Config.data.ffmpegPath == "" && fs.existsSync(Config.defaultFFmpegPath)) {
            Config.data.ffmpegPath = Config.defaultFFmpegPath;
        }

        if (!fs.existsSync(Config.data.exportPath)) {
            fs.mkdirSync(Config.data.exportPath);
        }

        if (!fs.existsSync(Config.tmpPath)) {
            fs.mkdirSync(Config.tmpPath);
        }
    }

    static update(data) {
        Config.data = data;
    }
}
