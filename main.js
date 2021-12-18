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

const {BrowserWindow, Menu, app, shell, dialog, ipcMain, nativeTheme} = require("electron")
const path = require("path")
const fs = require("fs")
const os = require("os")
const feed = require("feed-read");

const version = app.getVersion()
const icon = path.join(__dirname, "icon.png")

// App Menu
let template
let menu
let menuStatus = "viewStart"

// Windows
let win = null
let about = null
let progress = null
let license = null
let preferences = null
let update = null

function createWindows () {

	win = new BrowserWindow({
		title: "Silence SpeedUp",
		icon: icon,
		width: 750,
		height: 900,
		minWidth: 600,
		minHeight: 750,
		show: false,
		webPreferences: {
			nodeIntegration: true,
			contextIsolation: false
		}
	})

	win.loadFile("index.html")

	win.once("ready-to-show", () => {
		win.show()
	})

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
	})

	about.menuBarVisible = false
	about.excludedFromShownWindowsMenu = true
	about.loadFile("assets/pages/about/about.html")

	about.webContents.on("new-window", (event, url) => {
		event.preventDefault()
		shell.openExternal(url)
	})

	about.on("close", (event) => {
		event.preventDefault()
		about.hide()
	})

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
	})

	license.menuBarVisible = false
	license.excludedFromShownWindowsMenu = true
	license.loadFile("LICENSE.html")

	license.webContents.on("new-window", (event, url) => {
		event.preventDefault()
		shell.openExternal(url)
	})

	license.on("close", (event) => {
		event.preventDefault()
		license.hide()
	})

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
	})

	progress.menuBarVisible = false
	progress.loadFile("assets/pages/progress/progress.html")

	progress.on("close", (event) => {
		event.preventDefault()
		progress.hide()
		win.show()
	})

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
	})

	update.menuBarVisible = false
	update.excludedFromShownWindowsMenu = true
	update.loadFile("assets/pages/update/update.html")

	update.webContents.on("new-window", (event, url) => {
		event.preventDefault()
		shell.openExternal(url)
	})

	update.on("close", (event) => {
		event.preventDefault()
		update.hide()
	})


	win.on("closed", () => {
		// Dereference the window object, usually you would store windows
		// in an array if your app supports multi windows, this is the time
		// when you should delete the corresponding element.
		preferences = null
		update = null
		progress = null
		about = null
		license = null
		win = null
	})
}

function setupMenu(lang) {
	langPath = path.join(__dirname, "assets", "menu", `lang_${lang}.js`)
	if(! fs.existsSync(langPath))
		langPath = path.join(__dirname, "assets", "menu", "lang_EN.js")

	langLabels = require(langPath)
	template = require(path.join(__dirname, "assets", "menu", "template.js"))(langLabels, version)
	menu = Menu.buildFromTemplate(template)

	// Check current settings
	setTheme()
	menu.getMenuItemById(`lang_${lang}`).checked = true

	// Set click functions
	menu.getMenuItemById("openFile").click = (item, focusedWindow) => { openFile() }
	menu.getMenuItemById("openFolder").click = (item, focusedWindow) => { openFolder() }
	menu.getMenuItemById("preferences").click = () => { showPreferences() }
	menu.getMenuItemById("restart").click = () => { reload() }
	menu.getMenuItemById("quit").click = (item, focusedWindow) => { win.send("stopAndExit") }
	menu.getMenuItemById("start").click = () => { win.send("start") }
	menu.getMenuItemById("stop").click = () => { win.send("stop") }
	menu.getMenuItemById("progress").click = () => { switchToProgressMode() }
	menu.getMenuItemById("lightMode").click = () => { setTheme("light") }
	menu.getMenuItemById("darkMode").click = () => { setTheme("dark") }
	menu.getMenuItemById("lang_EN").click = () => { setupMenu("EN") }
	menu.getMenuItemById("lang_IT").click = () => { setupMenu("IT") }
	menu.getMenuItemById("cleanShell").click = () => { win.send("cleanShell") }
	menu.getMenuItemById("toggleDevTools").click = async () => { win.toggleDevTools() }
	menu.getMenuItemById("update").click = async () => { update.show() }
	menu.getMenuItemById("about").click = async () => { showAbout() }
	menu.getMenuItemById("license").click = async () => { showLicense() }
	menu.getMenuItemById("issue").click = async () => { shell.openExternal("https://github.com/padvincenzo/silence-speedup/issues") }
	menu.getMenuItemById("sourceCode").click = async () => { shell.openExternal("https://github.com/padvincenzo/silence-speedup") }
	menu.getMenuItemById("ffmpeg").click = async () => { shell.openExternal("https://ffmpeg.org/") }
	menu.getMenuItemById("electron").click = async () => { shell.openExternal("https://www.electronjs.org/") }

	menuEnabler()

	Menu.setApplicationMenu(menu)
}

function checkUpdates() {
	feed("https://github.com/padvincenzo/silence-speedup/releases.atom", (err, articles) => {
		if (err)
			return;

		let currentVersion = parseInt(version.replace(/v|\./g, ""))
		let latestVersion = parseInt(articles[0].title.replace(/v|\./g, ""))

		if(latestVersion > currentVersion) {
			update.send("data", articles[0].title, articles[0].content, articles[0].link)
			menu.getMenuItemById("update").visible = true
		}
	})
}

function setTheme(theme = null) {
	switch (theme) {
		case "light": {
			nativeTheme.themeSource = "light";
			menu.getMenuItemById("lightMode").checked = true
			break;
		}
		case "dark": {
			nativeTheme.themeSource = "dark";
			menu.getMenuItemById("darkMode").checked = true
			break;
		}
		default: {
			menu.getMenuItemById(nativeTheme.shouldUseDarkColors ? "darkMode" : "lightMode").checked = true
		}
	}
}

function loadApp() {
	let locale = app.getLocale()
	let initialLang = (locale == "it" || locale == "it-IT") ? "IT" : "EN"
	setupMenu(initialLang)
	createWindows()
	checkUpdates()
}

function reload() {
	win.send("stop")
	win.reload()
	about.reload()
	progress.reload()
	checkUpdates()
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on("ready", () => {
	loadApp()
})

// Quit when all windows are closed.
app.on("window-all-closed", () => {
	app.quit()
})

app.on("activate", () => {
	// On macOS it's common to re-create a window in the app when the
	// dock icon is clicked and there are no other windows open.
	if (win === null) {
		loadApp()
	}
})

function showLicense() {
	license.show()
}

function showAbout() {
	about.show()
}

ipcMain.on("showAbout", (event) => {
	showAbout()
})

function showPreferences() {
	if(preferences != null)
		return

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
	})

	preferences.menuBarVisible = false
	preferences.excludedFromShownWindowsMenu = true
	preferences.loadFile("assets/pages/preferences/preferences.html")

	preferences.once("ready-to-show", () => {
		preferences.show()
	})

	preferences.on("close", (event) => {
		preferences = null
	})
}

ipcMain.on("showPreferences", (event) => {
	showPreferences()
})

ipcMain.on("exportChoose", (event) => {
	event.returnValue = dialog.showOpenDialogSync(preferences, {
		title: "Select where to export videos",
		properties:["openDirectory", "createDirectory"]
	})
})

ipcMain.on("ffmpegChoose", (event) => {
	event.returnValue = dialog.showOpenDialogSync(preferences, {
    title: "Select ffmpeg executable",
    properties:['openFile']
  })
})

ipcMain.on("preferencesUpdate", (event, data) => {
	win.send("preferencesUpdate", data)
})

function openFile() {
	fileNames = dialog.showOpenDialogSync(win, {
    title: "Select one or more videos",
    filters: [
      {name:"Video", extensions:["avi", "flv", "mkv", "mov", "mp4", "webm", "wmv"]}
    ],
    properties:["openFile", "multiSelections"]
  })

  win.send("selectedFiles", fileNames)
}

ipcMain.on("selectFiles", (event) => {
  openFile()
})

function openFolder() {
	folder = dialog.showOpenDialogSync(win, {
    title: "Select a folder",
    properties:["openDirectory"]
  })

  win.send("selectedFolder", folder)
}

ipcMain.on("selectFolder", (event) => {
  openFolder()
})

function switchToProgressMode() {
	win.hide()
	progress.showInactive()
}

ipcMain.on("switchToProgressMode", (event) => {
	switchToProgressMode()
})

function progressUpdate(id, value) {
	progress.send(id, value)
}

ipcMain.on("progressUpdate", (event, id, value) => {
	progressUpdate(id, value)
})

function switchToDefaultMode() {
	progress.hide()
	win.show()
}

ipcMain.on("switchToDefaultMode", (event) => {
	switchToDefaultMode()
})

function menuEnabler(change = menuStatus) {
	switch(change) {
		case "lock": {
			menu.getMenuItemById("openFile").enabled = false
			menu.getMenuItemById("openFolder").enabled = false
			menu.getMenuItemById("start").enabled = false
			menu.getMenuItemById("stop").enabled = false
			menu.getMenuItemById("progress").enabled = false
			break
		}
		case "unlock": {
			menu.getMenuItemById("openFile").enabled = true
			menu.getMenuItemById("openFolder").enabled = true
			menu.getMenuItemById("start").enabled = false
			menu.getMenuItemById("stop").enabled = false
			menu.getMenuItemById("progress").enabled = false
			break
		}
		case "viewStart": {
			menu.getMenuItemById("openFile").enabled = true
			menu.getMenuItemById("openFolder").enabled = true
			menu.getMenuItemById("start").enabled = true
			menu.getMenuItemById("stop").enabled = false
			menu.getMenuItemById("progress").enabled = false
			menu.getMenuItemById("preferences").enabled = true
			break
		}
		case "viewStop": {
			menu.getMenuItemById("openFile").enabled = false
			menu.getMenuItemById("openFolder").enabled = false
			menu.getMenuItemById("start").enabled = false
			menu.getMenuItemById("stop").enabled = true
			menu.getMenuItemById("progress").enabled = true
			menu.getMenuItemById("preferences").enabled = false
			break
		}
	}
	menuStatus = change
}

ipcMain.on("menuEnabler", (event, change) => {
	menuEnabler(change)
})

ipcMain.on("setProgressBar", (event, value) => {
	win.setProgressBar(value)
	progress.setProgressBar(value)
})


ipcMain.on("quit", (event) => {
	win.close()
	app.quit()
})

nativeTheme.on("updated", (event) => {

})
