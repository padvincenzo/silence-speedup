const electron = require("electron");
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;
const dialog = electron.dialog;
const ipc = electron.ipcMain;
const shell = electron.shell;
const path = require("path");
const fs = require("fs");
const os = require("os");

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let win;
let credits;
let progress;
let icon = path.join(__dirname, "icon.png");

function createWindow () {
	// Create the browser window.
	win = new BrowserWindow({
		icon: icon,
		width: 800,
		height: 750,
		minWidth: 600,
		minHeight: 750,
		backgroundColor: "#eeeeee",
		webPreferences: {
			nodeIntegration: true,
			enableRemoteModule: true
		}
	});

	//win.menuBarVisible = false;
	win.loadFile("index.html");

	credits = new BrowserWindow({
		parent: win,
		modal: true,
		width: 400,
		height: 500,
		backgroundColor: "#eeeeee",
		show: false
	});

	credits.menuBarVisible = false;
	credits.loadFile("credits.html");

	credits.on("close", (event) => {
		event.preventDefault();
		credits.hide();
	});

	credits.webContents.on("new-window", (event, url) => {
		event.preventDefault();
		shell.openExternal(url);
	});

	progress = new BrowserWindow({
		parent: win,
		icon: icon,
		width: 700,
		height: 40,
		backgroundColor: "#eeeeee",
		show: false,
		frame: false,
		alwaysOnTop: true,
		webPreferences: {
			nodeIntegration: true
		}
	});

	progress.menuBarVisible = false;
	progress.setResizable(false);
	progress.loadFile("progress.html");

	progress.on("close", (event) => {
		event.preventDefault();
		progress.hide();
		win.show();
	});

	// progress.on("resize", (event) => {
	// 	console.log(progress.getSize());
	// });

	// Emitted when the window is closed.
	win.on("closed", () => {
		// Dereference the window object, usually you would store windows
		// in an array if your app supports multi windows, this is the time
		// when you should delete the corresponding element.
		credits = null;
		progress = null;
		win = null;
	});
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on("ready", createWindow);

// Quit when all windows are closed.
app.on("window-all-closed", () => {
	// On macOS it is common for applications and their menu bar
	// to stay active until the user quits explicitly with Cmd + Q
	if (process.platform !== "darwin") {
		app.quit();
	}
});

app.on("activate", () => {
	// On macOS it's common to re-create a window in the app when the
	// dock icon is clicked and there are no other windows open.
	if (win === null) {
		createWindow();
	}
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.

ipc.on("selectFiles", (event) => {
  fileNames = dialog.showOpenDialogSync(win, {
    title: "Seleziona uno o più video",
    filters: [
      {name:"Video", extensions:["avi", "mkv", "mp4"]}
    ],
    properties:['openFile', 'multiSelections']
  });

  win.send("selectedFiles", fileNames);
});

ipc.on("selectFolder", (event) => {
  folder = dialog.showOpenDialogSync(win, {
    title: "Seleziona una cartella",
    properties:['openDirectory']
  });

  win.send("selectedFolder", folder);
});

ipc.on("setProgressBar", (event, value) => {
	win.setProgressBar(value);
});

ipc.on("showCredits", (event) => {
	credits.show();
});

ipc.on("viewMainWindow", (event) => {
	progress.hide();
	win.show();
});

ipc.on("viewProgressWindow", (event) => {
	win.hide();
	progress.show();
});

ipc.on("changeTotal", (event, value) => {
	progress.send("changeTotal", value);
});

ipc.on("changeCompleted", (event, value) => {
	progress.send("changeCompleted", value);
});

ipc.on("changeName", (event, value) => {
	progress.send("changeName", value);
});

ipc.on("changeStatus", (event, value) => {
	progress.send("changeStatus", value);
});

ipc.on("changeProgressBar", (event, value) => {
	progress.send("changeProgressBar", value);
});
