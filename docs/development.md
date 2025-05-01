# 🛠 Development Guide – Silence Speedup

This document explains how to build, run, and package Silence Speedup from source.

---

## 🔧 Prerequisites

- [Node.js](https://nodejs.org/) updated
- Git
- FFmpeg binaries (optional if running from source, required for build packaging)

---

## ▶️ Running from Source

```bash
git clone https://github.com/padvincenzo/silence-speedup
cd silence-speedup
npm install
npm start
```

This launches the Electron app in development mode.

## 📦 Packaging
To create a distributable version of the app:

```bash
npm run package
```

This uses [electron-packager](https://github.com/electron/electron-packager)
and builds platform-specific binaries.

To include FFmpeg binaries in the package, refer to
the [discussion here](https://github.com/padvincenzo/silence-speedup/discussions/6).

## 🧪 Testing
Currently, no automated test suite is available. Please test changes manually through the GUI.
Consider contributing tests if you’re interested in helping with automation.

## 🔁 Directory Structure
```bash
silence-speedup/
├── main.js              # Electron main process
├── src/
|   |── classes/         # App classes
|   |── menu/            # App menu structure
|   |── renderer/        # Frontend (UI) files
├── assets/              # Icons and screenshots
├── docs/                # Documentation
├── package.json         # Project metadata and scripts
```

## 📋 Build Targets
To build for a specific OS:

```bash
npm run package-win
npm run package-mac
npm run package-linux
```

> These scripts must be added manually to your `package.json`
> or handled with tools like `electron-builder` or `electron-forge`.

## 💬 Need Help?
Open a [GitHub Discussion](https://github.com/padvincenzo/silence-speedup/discussions)
or create an issue if you run into problems.
