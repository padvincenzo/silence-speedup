/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

const { BrowserWindow, Menu, app, shell, dialog, ipcMain, nativeTheme, Notification } = require("electron");
const path = require("path");
const fs = require("fs");
const os = require("os");
const https = require("https");
const i18next = require("i18next");
const Backend = require("i18next-fs-backend");
const { t } = require("i18next");

const version = app.getVersion();
const icon = path.join(__dirname, "assets/icons/icon.png");

// App Menu
let menu;
let menuStatus = "viewStart";

// Windows
let win = null;
let about = null;
let progress = null;
let license = null;
let preferences = null;
let update = null;

function createWindows() {

    win = new BrowserWindow({
        title: "Silence SpeedUp",
        icon: icon,
        width: 650,
        height: 800,
        minWidth: 600,
        minHeight: 450,
        show: false,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    win.loadFile("src/renderer/index/index.html");

    win.once("ready-to-show", () => {
        win.show();
    });

    about = new BrowserWindow({
        parent: win,
        title: "About Silence SpeedUp",
        show: false,
        icon: icon,
        width: 400,
        height: 500,
        show: false,
        resizable: false,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    about.menuBarVisible = false;
    about.excludedFromShownWindowsMenu = true;
    about.loadFile("src/renderer/about/about.html");

    about.webContents.on("new-window", (event, url) => {
        event.preventDefault();
        shell.openExternal(url);
    });

    about.on("close", (event) => {
        event.preventDefault();
        about.hide();
    });

    license = new BrowserWindow({
        parent: win,
        icon: icon,
        show: false,
        width: 650,
        height: 750,
        show: false,
        webPreferences: {
            contextIsolation: false
        }
    });

    license.menuBarVisible = false;
    license.excludedFromShownWindowsMenu = true;
    license.loadFile("LICENSE.html");

    license.webContents.on("new-window", (event, url) => {
        event.preventDefault();
        shell.openExternal(url);
    });

    license.on("close", (event) => {
        event.preventDefault();
        license.hide();
    });

    progress = new BrowserWindow({
        parent: win,
        title: "",
        icon: icon,
        width: 700,
        height: 40,
        resizable: false,
        show: false,
        frame: false,
        alwaysOnTop: true,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    progress.menuBarVisible = false;
    progress.loadFile("src/renderer/progress/progress.html");

    progress.on("close", (event) => {
        event.preventDefault();
        progress.hide();
        win.show();
    });

    update = new BrowserWindow({
        parent: win,
        icon: icon,
        width: 400,
        height: 300,
        show: false,
        webPreferences: {
            contextIsolation: false,
            nodeIntegration: true
        }
    });

    update.menuBarVisible = false;
    update.excludedFromShownWindowsMenu = true;
    update.loadFile("src/renderer/update/update.html");

    update.webContents.on("new-window", (event, url) => {
        event.preventDefault();
        shell.openExternal(url);
    });

    update.on("close", (event) => {
        event.preventDefault();
        update.hide();
    });


    win.on("closed", () => {
        // Dereference the window object, usually you would store windows
        // in an array if your app supports multi windows, this is the time
        // when you should delete the corresponding element.
        preferences = null;
        update = null;
        progress = null;
        about = null;
        license = null;
        win = null;
    });
}

function setupMenu() {
    let template = [
        {
            id: "file",
            label: t("menu.file"),
            submenu: [
                {
                    id: "openFile",
                    label: t("menu.openFile"),
                    accelerator: "CmdOrCtrl+O",
                    click: (item, focusedWindow) => { openFile(); }
                },
                {
                    id: "openFolder",
                    label: t("menu.openFolder"),
                    accelerator: "Shift+CmdOrCtrl+O",
                    click: (item, focusedWindow) => { openFolder(); }
                },
                { type: "separator" },
                {
                    id: "preferences",
                    label: t("menu.preferences"),
                    click: (item, focusedWindow) => { showPreferences(); }
                },
                { type: "separator" },
                {
                    id: "restart",
                    label: t("menu.restart"),
                    accelerator: "CmdOrCtrl+R",
                    click: (item, focusedWindow) => { reload(); }
                },
                {
                    id: "quit",
                    label: t("menu.quit"),
                    accelerator: "CmdOrCtrl+Q",
                    click: (item, focusedWindow) => { win.send("stopAndExit"); }
                }
            ]
        },
        {
            id: "media",
            label: t("menu.media"),
            submenu: [
                {
                    id: "start",
                    label: t("process.start"),
                    click: (item, focusedWindow) => { win.send("start"); }
                },
                {
                    id: "stop",
                    label: t("process.stop"),
                    accelerator: "CmdOrCtrl+D",
                    enabled: false,
                    click: (item, focusedWindow) => { win.send("stop"); }
                }
            ]
        },
        {
            id: "view",
            label: t("menu.view"),
            submenu: [
                {
                    id: "progress",
                    label: t("menu.progress"),
                    enabled: false,
                    click: (item, focusedWindow) => { switchToProgressMode(); }
                },
                { type: "separator" },
                {
                    id: "theme",
                    label: t("ui.theme"),
                    submenu: [
                        {
                            id: "lightMode",
                            label: t("ui.lightMode"),
                            type: "radio",
                            click: (item, focusedWindow) => { setTheme("light"); }
                        },
                        {
                            id: "darkMode",
                            label: t("ui.darkMode"),
                            type: "radio",
                            click: (item, focusedWindow) => { setTheme("dark"); }
                        }
                    ]
                },
                {
                    id: "language",
                    label: t("ui.language"),
                    submenu: [
                        {
                            id: "lang.en",
                            label: "English",
                            type: "radio",
                            checked: i18next.language === "en",
                            click: (item, focusedWindow) => { changeLanguage("en"); }
                        },
                        {
                            id: "lang.it",
                            label: "Italiano",
                            type: "radio",
                            checked: i18next.language === "it",
                            click: (item, focusedWindow) => { changeLanguage("it"); }
                        }
                    ]
                },
                { type: "separator" },
                {
                    id: "cleanShell",
                    label: t("menu.cleanShell"),
                    click: (item, focusedWindow) => { win.send("cleanShell"); }
                },
                {
                    id: "toggleDevTools",
                    label: t("menu.toggleDevTools"),
                    accelerator: (() => {
                        return (process.platform === "darwin") ? "Alt+Command+I" : "Ctrl+Shift+I"
                    })(),
                    click: async (item, focusedWindow) => { win.toggleDevTools(); }
                }
            ]
        },
        {
            id: "help",
            label: t("menu.help"),
            role: "help",
            submenu: [
                {
                    id: "version",
                    label: t("menu.version", { version: version }),
                    enabled: false
                },
                {
                    id: "update",
                    label: t("menu.update"),
                    visible: false,
                    click: async (item, focusedWindow) => { update.show(); }
                },
                { type: "separator" },
                {
                    id: "about",
                    label: t("menu.about"),
                    click: async (item, focusedWindow) => { showAbout(); }
                },
                {
                    id: "license",
                    label: t("menu.license"),
                    click: async (item, focusedWindow) => { showLicense(); }
                },
                {
                    id: "donate",
                    label: t("menu.donate"),
                    click: async (item, focusedWindow) => { shell.openExternal("https://paypal.me/VincenzoPadula"); }
                },
                { type: "separator" },
                {
                    id: "issue",
                    label: t("menu.issue"),
                    click: async (item, focusedWindow) => { shell.openExternal("https://github.com/padvincenzo/silence-speedup/issues"); }
                },
                {
                    id: "ref",
                    label: t("menu.references"),
                    submenu:
                        [
                            {
                                id: "sourceCode",
                                label: t("menu.sourceCode"),
                                click: async (item, focusedWindow) => { shell.openExternal("https://github.com/padvincenzo/silence-speedup"); }
                            },
                            {
                                id: "ffmpeg",
                                label: t("menu.ffmpeg"),
                                click: async (item, focusedWindow) => { shell.openExternal("https://ffmpeg.org/"); }
                            },
                            {
                                id: "electron",
                                label: t("menu.electron"),
                                click: async (item, focusedWindow) => { shell.openExternal("https://www.electronjs.org/"); }
                            }
                        ]
                }
            ]
        }
    ];

    menu = Menu.buildFromTemplate(template);

    // Check current settings
    setTheme();

    menuEnabler();

    Menu.setApplicationMenu(menu);
}

// Compares dotted versions component by component; positive when a is newer.
// A leading "v" and any suffix are ignored, and a missing component is zero.
function compareVersions(a, b) {
    const components = (value) => {
        let match = /(\d+(?:\.\d+)*)/.exec(String(value));
        return match == null
            ? [0]
            : match[1].split(".").map((part) => parseInt(part, 10) || 0);
    };

    let left = components(a);
    let right = components(b);

    for (let i = 0; i < left.length || i < right.length; i++) {
        let difference = (left[i] || 0) - (right[i] || 0);
        if (difference != 0) {
            return difference;
        }
    }

    return 0;
}

const releasesUrl = "https://github.com/padvincenzo/silence-speedup/releases";
const releasesFeedUrl = releasesUrl + ".atom";

// Newest <entry> of an Atom feed, or null if it cannot be read. GitHub
// redirects this URL, so redirects are followed.
function fetchLatestRelease(url, callback, redirects = 0) {
    const request = https.get(
        url,
        { headers: { "User-Agent": "silence-speedup", "Accept": "application/atom+xml" } },
        (response) => {
            const location = response.headers.location;
            if (response.statusCode >= 300 && response.statusCode < 400 && location) {
                response.resume();
                return redirects < 3
                    ? fetchLatestRelease(location, callback, redirects + 1)
                    : callback(null);
            }

            if (response.statusCode != 200) {
                response.resume();
                return callback(null);
            }

            let body = "";
            response.setEncoding("utf8");
            response.on("data", (chunk) => { body += chunk; });
            response.on("end", () => { callback(parseLatestRelease(body)); });
        }
    );

    request.on("error", () => { callback(null); });
    request.setTimeout(8000, () => { request.destroy(); });
}

function parseLatestRelease(xml) {
    const entry = /<entry>([\s\S]*?)<\/entry>/.exec(xml);
    if (entry == null) {
        return null;
    }

    const title = /<title[^>]*>([\s\S]*?)<\/title>/.exec(entry[1]);
    if (title == null) {
        return null;
    }

    const link = /<link[^>]*href="([^"]+)"/.exec(entry[1]);
    const content = /<content[^>]*>([\s\S]*?)<\/content>/.exec(entry[1]);

    return {
        title: title[1].trim(),
        content: content == null ? "" : content[1],
        link: link == null ? releasesUrl : link[1]
    };
}

function checkUpdates() {
    fetchLatestRelease(releasesFeedUrl, (release) => {
        if (release == null || compareVersions(release.title, version) <= 0) {
            return;
        }

        update.send("data", release.title, release.content, release.link);
        menu.getMenuItemById("update").visible = true;
    });
}

function setTheme(theme = null) {
    switch (theme) {
        case "light": {
            nativeTheme.themeSource = "light";
            menu.getMenuItemById("lightMode").checked = true;
            break;
        }
        case "dark": {
            nativeTheme.themeSource = "dark";
            menu.getMenuItemById("darkMode").checked = true;
            break;
        }
        default: {
            menu.getMenuItemById(nativeTheme.shouldUseDarkColors ? "darkMode" : "lightMode").checked = true;
        }
    }
}

async function loadApp() {
    await i18next
        .use(Backend)
        .init({
            backend: {
                loadPath: path.join(__dirname, "locales/{{lng}}/translation.json")
            },
            lng: app.getLocale(), // localStorage.getItem("language") || app.getLocale(),
            fallbackLng: "en",
            preload: ["en", "it"]
        });

    setupMenu();
    createWindows();
    checkUpdates();
}

function reload() {
    win.send("stop");
    win.reload();
    about.reload();
    progress.reload();
    checkUpdates();
}

async function changeLanguage(lang) {
    await i18next.changeLanguage(lang);
    // localStorage.setItem("language", lang);

    win?.webContents.send("languageChanged", lang);
    about?.webContents.send("languageChanged", lang);
    progress?.webContents.send("languageChanged", lang);
    license?.webContents.send("languageChanged", lang);
    preferences?.webContents.send("languageChanged", lang);
    update?.webContents.send("languageChanged", lang);

    setupMenu();
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on("ready", () => {
    loadApp();
});

// Quit when all windows are closed.
app.on("window-all-closed", () => {
    app.quit();
});

app.on("activate", () => {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (win === null) {
        loadApp();
    }
});

function showLicense() {
    license.show();
}

function showAbout() {
    about.show();
}

ipcMain.on("showAbout", (event) => {
    showAbout();
});

function showPreferences() {
    if (preferences != null) {
        preferences.show();
        return;
    }

    preferences = new BrowserWindow({
        parent: win,
        modal: true,
        title: "Silence SpeedUp - Preferences",
        icon: icon,
        width: 600,
        height: 320,
        minWidth: 580,
        minHeight: 320,
        show: false,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    preferences.menuBarVisible = false;
    preferences.excludedFromShownWindowsMenu = true;
    preferences.loadFile("src/renderer/preferences/preferences.html");

    preferences.once("ready-to-show", () => {
        preferences.show();
    });

    preferences.on("close", (event) => {
        preferences = null;
    });
}

ipcMain.on("getInitialData", (event) => {
    event.returnValue = { language: i18next.language };
});

ipcMain.on("showPreferences", (event) => {
    showPreferences();
});

ipcMain.on("exportChoose", (event) => {
    event.returnValue = dialog.showOpenDialogSync(preferences, {
        title: t("preference.chooseExportDir"),
        properties: ["openDirectory", "createDirectory"]
    });
});

ipcMain.on("ffmpegChoose", (event) => {
    event.returnValue = dialog.showOpenDialogSync(preferences, {
        title: t("preference.chooseFFmpegPath"),
        properties: ['openFile']
    });
});

ipcMain.on("preferencesUpdate", (event, data) => {
    win.send("preferencesUpdate", data);
    preferences.hide();
});

function openFile() {
    fileNames = dialog.showOpenDialogSync(win, {
        title: t("file.openFile"),
        filters: [
            { name: "Video", extensions: ["avi", "flv", "mkv", "mov", "mp4", "webm", "wmv"] }
        ],
        properties: ["openFile", "multiSelections"]
    });

    win.send("selectedFiles", fileNames);
}

ipcMain.on("selectFiles", (event) => {
    openFile();
});

function openFolder() {
    folder = dialog.showOpenDialogSync(win, {
        title: t("file.openDir"),
        properties: ["openDirectory"]
    });

    win.send("selectedFolder", folder);
}

ipcMain.on("selectFolder", (event) => {
    openFolder();
});

function switchToProgressMode() {
    win.hide();
    progress.showInactive();
}

ipcMain.on("switchToProgressMode", (event) => {
    switchToProgressMode();
});

function progressUpdate(id, value) {
    progress.send(id, value);
}

ipcMain.on("progressUpdate", (event, id, value) => {
    progressUpdate(id, value);
});

function switchToDefaultMode() {
    progress.hide();
    win.show();
}

ipcMain.on("switchToDefaultMode", (event) => {
    switchToDefaultMode();
});

function menuEnabler(change = menuStatus) {
    switch (change) {
        case "lock": {
            menu.getMenuItemById("openFile").enabled = false;
            menu.getMenuItemById("openFolder").enabled = false;
            menu.getMenuItemById("start").enabled = false;
            menu.getMenuItemById("stop").enabled = false;
            menu.getMenuItemById("progress").enabled = false;
            break;
        }
        case "unlock": {
            menu.getMenuItemById("openFile").enabled = true;
            menu.getMenuItemById("openFolder").enabled = true;
            menu.getMenuItemById("start").enabled = false;
            menu.getMenuItemById("stop").enabled = false;
            menu.getMenuItemById("progress").enabled = false;
            break;
        }
        case "viewStart": {
            menu.getMenuItemById("openFile").enabled = true;
            menu.getMenuItemById("openFolder").enabled = true;
            menu.getMenuItemById("start").enabled = true;
            menu.getMenuItemById("stop").enabled = false;
            menu.getMenuItemById("progress").enabled = false;
            menu.getMenuItemById("preferences").enabled = true;
            break;
        }
        case "viewStop": {
            menu.getMenuItemById("openFile").enabled = false;
            menu.getMenuItemById("openFolder").enabled = false;
            menu.getMenuItemById("start").enabled = false;
            menu.getMenuItemById("stop").enabled = true;
            menu.getMenuItemById("progress").enabled = true;
            menu.getMenuItemById("preferences").enabled = false;
            break;
        }
    }
    menuStatus = change;
}

ipcMain.on("menuEnabler", (event, change) => {
    menuEnabler(change);
});

ipcMain.on("setProgressBar", (event, value) => {
    win.setProgressBar(value);
    progress.setProgressBar(value);

    // Send notification on complete
    if (value == 1) {
        new Notification({ title: t("app.title"), body: t("process.completed") }).show();
    }
});


ipcMain.on("quit", (event) => {
    win.close();
    app.quit();
});

nativeTheme.on("updated", (event) => {
});

ipcMain.on("demo", (event, data) => {
    let player = new BrowserWindow({
        title: t("player.title"),
        icon: icon,
        width: 800,
        height: 600,
        show: false,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false,
            webSecurity: false
        }
    });

    player.menuBarVisible = false;
    player.loadFile("src/renderer/player/player.html");

    player.once("ready-to-show", () => {
        player.send("init", data);
        player.show();
    });
});
