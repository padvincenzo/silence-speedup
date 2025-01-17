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

module.exports = (lang, version) => {
    return [
        {
            id: "file",
            label: lang.file,
            submenu: [
                {
                    id: "openFile",
                    label: lang.openFile,
                    accelerator: "CmdOrCtrl+O"
                },
                {
                    id: "openFolder",
                    label: lang.openFolder,
                    accelerator: "Shift+CmdOrCtrl+O"
                },
                { type: "separator" },
                {
                    id: "preferences",
                    label: lang.preferences
                },
                { type: "separator" },
                {
                    id: "restart",
                    label: lang.restart,
                    accelerator: "CmdOrCtrl+R"
                },
                {
                    id: "quit",
                    label: lang.quit,
                    accelerator: "CmdOrCtrl+Q"
                }
            ]
        },
        {
            id: "media",
            label: lang.media,
            submenu: [
                {
                    id: "start",
                    label: lang.start
                },
                {
                    id: "stop",
                    label: lang.stop,
                    accelerator: "CmdOrCtrl+D",
                    enabled: false
                }
            ]
        },
        {
            id: "view",
            label: lang.view,
            submenu: [
                {
                    id: "progress",
                    label: lang.progress,
                    enabled: false
                },
                { type: "separator" },
                {
                    id: "theme",
                    label: lang.theme,
                    submenu: [
                        {
                            id: "lightMode",
                            label: lang.lightMode,
                            type: "radio"
                        },
                        {
                            id: "darkMode",
                            label: lang.darkMode,
                            type: "radio"
                        }
                    ]
                },
                {
                    id: "language",
                    label: lang.language,
                    submenu: [
                        {
                            id: "lang_EN",
                            label: lang.lang_EN,
                            type: "radio"
                        },
                        {
                            id: "lang_IT",
                            label: lang.lang_IT,
                            type: "radio"
                        }
                    ]
                },
                { type: "separator" },
                {
                    id: "cleanShell",
                    label: lang.cleanShell
                },
                {
                    id: "toggleDevTools",
                    label: lang.toggleDevTools,
                    accelerator: (() => {
                        return (process.platform === "darwin") ? "Alt+Command+I" : "Ctrl+Shift+I"
                    })()
                }
            ]
        },
        {
            id: "help",
            label: lang.help,
            role: "help",
            submenu: [
                {
                    id: "version",
                    label: `${lang.version} ${version}`,
                    enabled: false
                },
                {
                    id: "update",
                    label: lang.update,
                    visible: false
                },
                { type: "separator" },
                {
                    id: "about",
                    label: lang.about
                },
                {
                    id: "license",
                    label: lang.license
                },
                { type: "separator" },
                {
                    id: "issue",
                    label: lang.issue
                },
                {
                    id: "ref",
                    label: lang.ref,
                    submenu:
                        [
                            {
                                id: "sourceCode",
                                label: lang.sourceCode
                            },
                            {
                                id: "ffmpeg",
                                label: lang.ffmpeg
                            },
                            {
                                id: "electron",
                                label: lang.electron
                            }
                        ]
                }
            ]
        }
    ]
}
