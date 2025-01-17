/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

module.exports = class Config {
    static configPathDefaults = path.join(__dirname, "..", "..", "config.json.example");
    static configPath = path.join(__dirname, "..", "..", "config.json");

    static defaultExportPath = path.join(os.homedir(), "speededup");
    static defaultFFmpegPath = path.join(__dirname, "..", "ffmpeg", (os.type() == "Windows_NT" ? "ffmpeg.exe" : "ffmpeg"));
    static tmpPath = path.join(__dirname, "..", "..", "tmp");
    static fragmentListPath = path.join(Config.tmpPath, "list.txt");

    static data = null;

    static load() {
        if (!fs.existsSync(Config.configPath)) {
            // Copy initial configuration.
            fs.copyFileSync(Config.configPathDefaults, Config.configPath);
        }

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
