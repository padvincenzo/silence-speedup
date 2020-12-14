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

class Config {
  static configPath = "config.json"

  static defaultExportPath = path.join(os.homedir(), "speededup")
  static exportPath = null

  static tmpPath = null
  static fragmentListPath = null

  static load() {
    if (!fs.existsSync(Config.configPath)) {
      fs.writeFileSync(Config.configPath,
        JSON.stringify({exportPath:Config.defaultExportPath}),
        {encoding: 'utf-8'})
    }

    console.log(Config.configPath)

    let json = fs.readFileSync(Config.configPath, {encoding: 'utf-8'})
    let config = JSON.parse(json)
    Config.exportPath = config.exportPath || Config.defaultExportPath

    Config.tmpPath = path.join(Config.exportPath, "speededup_tmp")
    Config.fragmentListPath = path.join(Config.exportPath, "list.txt")

    if (!fs.existsSync(Config.exportPath))
      fs.mkdirSync(Config.exportPath)

    if (!fs.existsSync(Config.tmpPath))
      fs.mkdirSync(Config.tmpPath)
  }

  static save(exportPath) {
    Config.exportPath = exportPath
  }
}

module.exports = Config
