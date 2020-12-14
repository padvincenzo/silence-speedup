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

const {BrowserWindow, Menu, app, shell, dialog, ipcMain} = require('electron')
const path = require("path")
const fs = require("fs")
const os = require("os")

const version = app.getVersion()
const icon = path.join(__dirname, "icon.png")
const bgColor = "#EEE"

// BrowserWindow(s)
let win = null
let credits = null
let progress = null
let license = null
let config = null

// Menu
let template = [
	{
		label: '&File',
		submenu: [
			{
				id: "1",
				label: 'Open video(s)',
				accelerator: 'CmdOrCtrl+O',
				click: (item, focusedWindow) => { openFile() }
			},
			{
				id: "2",
				label: 'Open folder',
				accelerator: 'Shift+CmdOrCtrl+O',
				click: (item, focusedWindow) => { openFolder() }
			},
			{
				type: 'separator'
			},
			{
				id: "3",
				label: 'Quit',
				accelerator: 'CmdOrCtrl+Q',
				click: (item, focusedWindow) => { win.send("stopAndExit") }
			}
		]
	},
	{
		label: '&Media',
		submenu: [
			{
				id: "4",
				label: 'Start',
				click: () => { win.send("start") }
			},
			{
				id: "5",
				label: 'Stop',
				enabled: false,
				click: () => { win.send("stop") }
			}
		]
	},
	{
		label: '&Help',
		role: 'help',
		submenu: [
			{
				label: `Version ${version}`,
				enabled: false
			},
			{
				type: 'separator'
			},
			{
				label: 'About',
				click: async () => { credits.show() }
			},
			{
				label: 'View License',
				click: () => {
					// Go to first line
					license.webContents.executeJavaScript("window.scrollTo(0, 0);");
					license.show()
				}
			},
			{
				type: 'separator'
			},
			{
				label: 'Issues',
				submenu:
				[
					{
						label: 'Toggle Dev Tools',
						accelerator: (() => {
							return (process.platform === 'darwin') ? 'Alt+Command+I' : 'Ctrl+Shift+I'
						})(),
						click: (item, focusedWindow) => { win.toggleDevTools() }
					},
					{
						label: 'Report issue',
						click: async () => { shell.openExternal('https://github.com/padvincenzo/silence-speedup/issues') }
					}
				]
			},
			{
				label: 'References',
				submenu:
				[
					{
						label: 'Source code',
						click: async () => { shell.openExternal('https://github.com/padvincenzo/silence-speedup') }
					},
					{
						label: 'FFmpeg',
						click: async () => { shell.openExternal('https://ffmpeg.org/') }
					},
					{
						label: 'Electron',
						click: async () => { shell.openExternal('https://www.electronjs.org/') }
					}
				]
			}
		]
	}
]

const menu = Menu.buildFromTemplate(template)

function createWindows () {
	// Set application menu
	Menu.setApplicationMenu(menu)

	// Create the browser window.
	win = new BrowserWindow({
		title: "Silence SpeedUp",
		icon: icon,
		width: 750,
		height: 800,
		minWidth: 600,
		minHeight: 750,
		backgroundColor: bgColor,
		webPreferences: {
			nodeIntegration: true,
			contextIsolation: false
		}
	})

	win.loadFile("index.html")

	credits = new BrowserWindow({
		parent: win,
		title: "Silence SpeedUp - Credits",
		icon: icon,
		width: 400,
		height: 500,
		resizable: false,
		backgroundColor: bgColor,
		show: false,
		webPreferences: {
			nodeIntegration: true,
			contextIsolation: false
		}
	})

	credits.menuBarVisible = false
	credits.loadFile("assets/pages/credits/credits.html")
	// credits.openDevTools()
	credits.excludedFromShownWindowsMenu = true

	credits.on("close", (event) => {
		event.preventDefault()
		credits.hide()
	})

	credits.webContents.on("new-window", (event, url) => {
		event.preventDefault()
		shell.openExternal(url)
	})

	progress = new BrowserWindow({
		parent: win,
		title: "",
		icon: icon,
		width: 700,
		height: 40,
		resizable: false,
		backgroundColor: bgColor,
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

	license = new BrowserWindow({
		parent: win,
		title: "Silence SpeedUp - License",
		icon: icon,
		width: 650,
		height: 750,
		resizable: false,
		backgroundColor: bgColor,
		show: false,
		webPreferences: {
			contextIsolation: false
		}
	})

	license.menuBarVisible = false
	license.loadFile("LICENSE")
	license.excludedFromShownWindowsMenu = true

	license.on("close", (event) => {
		event.preventDefault()
		license.hide()
	})

	config = new BrowserWindow({
		parent: win,
		modal: true,
		title: "Silence SpeedUp - Configuration",
		icon: icon,
		width: 600,
		height: 320,
		resizable: false,
		backgroundColor: bgColor,
		show: false,
		webPreferences: {
			nodeIntegration: true,
			contextIsolation: false
		}
	})

	config.menuBarVisible = false
	config.loadFile("assets/pages/config/config.html")
	// config.openDevTools()
	config.excludedFromShownWindowsMenu = true

	config.on("close", (event) => {
		event.preventDefault()
		config.hide()
		win.send("configReload")
	})

	// Emitted when the window is closed.
	win.on("closed", () => {
		// Dereference the window object, usually you would store windows
		// in an array if your app supports multi windows, this is the time
		// when you should delete the corresponding element.
		config = null
		license = null
		credits = null
		progress = null
		win = null
	})
}

function openFile() {
	fileNames = dialog.showOpenDialogSync(win, {
    title: "Select one or more videos",
    filters: [
      {name:"Video", extensions:["avi", "flv", "mkv", "mov", "mp4", "webm", "wmv"]}
    ],
    properties:['openFile', 'multiSelections']
  })

  win.send("selectedFiles", fileNames)
}

function openFolder() {
	folder = dialog.showOpenDialogSync(win, {
    title: "Select a folder",
    properties:['openDirectory']
  })

  win.send("selectedFolder", folder)
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on("ready", createWindows)

// Quit when all windows are closed.
app.on("window-all-closed", () => {
	app.quit()
})

app.on("activate", () => {
	// On macOS it's common to re-create a window in the app when the
	// dock icon is clicked and there are no other windows open.
	if (win === null) {
		createWindows()
	}
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.

ipcMain.on("selectFiles", (event) => {
  openFile()
})

ipcMain.on("selectFolder", (event) => {
  openFolder()
})

ipcMain.on("menuEnabler", (event, enabled) => {
	menu.getMenuItemById("1").enabled = enabled
	menu.getMenuItemById("2").enabled = enabled
	menu.getMenuItemById("3").enabled = enabled
	menu.getMenuItemById("4").enabled = !enabled
})

ipcMain.on("setProgressBar", (event, value) => {
	win.setProgressBar(value)
})

ipcMain.on("showCredits", (event) => {
	credits.show()
})

ipcMain.on("viewMainWindow", (event) => {
	progress.hide()
	win.show()
	win.focus()
})

ipcMain.on("viewProgressWindow", (event) => {
	win.hide()
	progress.showInactive()
})

ipcMain.on("changeTotal", (event, value) => {
	progress.send("changeTotal", value)
})

ipcMain.on("changeCompleted", (event, value) => {
	progress.send("changeCompleted", value)
})

ipcMain.on("changeName", (event, value) => {
	progress.send("changeName", value)
})

ipcMain.on("changeStatus", (event, value) => {
	progress.send("changeStatus", value)
})

ipcMain.on("changeProgressBar", (event, value) => {
	progress.send("changeProgressBar", value)
})

ipcMain.on("showWarrantyDetails", (event, value) => {
	// Go to paragraph 15
	license.webContents.executeJavaScript("window.scrollTo(0, 8820);");
	license.show()
})

ipcMain.on("showRedistributingDetails", (event, value) => {
	// Go to paragraph 16
	license.webContents.executeJavaScript("window.scrollTo(0, 8980);");
	license.show()
})

ipcMain.on("showConfig", (event) => {
	config.webContents.executeJavaScript("load();");
	config.show()
})

ipcMain.on("exportChoose", (event) => {
	folder = dialog.showOpenDialogSync(config, {
    title: "Select where to export videos",
    properties:['openDirectory', 'createDirectory']
  })

  config.send("exportChoosen", folder)
})

ipcMain.on("quit", (event) => {
	win.close()
	app.quit()
})
