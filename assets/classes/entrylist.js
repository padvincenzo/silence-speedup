/**
 * This file is part of Silence SpeedUp, an electron-based app
 * that speed-up your videos by speeding-up (or removing) silences,
 * using FFmpeg.
 *
 * @author Vincenzo Padula <padvincenzo@gmail.com>
 * @copyright 2025
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

const { entryListTable } = require("./interface");

module.exports = class EntryList {
    static list = {};
    static canImport = true;

    static import(urls) {
        if (urls == undefined || urls == null) {
            return 0;
        }

        console.log(urls);

        if (!EntryList.canImport) {
            return 0;
        }

        let len = urls.length;
        if (len == 0) {
            return 0;
        }

        let c = 0;

        // Hide the welcome message and display the entry table.
        Interface.entryMessage.classList.add("d-none");
        Interface.entryListTable.classList.remove("d-none");

        for (var i = 0; i < len; i++) {
            let url = urls[i].toString();

            let name = Entry.getNameFromUrl(url);
            let extension = Entry.getExtensionFromName(name);
            if (Entry.isExtensionValid(extension)) {
                if (EntryList.list.hasOwnProperty(name)) {
                    Shell.log(`Cannot load ${name}: file name already exists.`);
                } else {
                    var entry = new Entry(url, name, extension);
                    EntryList.list[name] = entry;
                    c++;
                }
            }
        }

        return c;
    }

    static remove(name) {
        var entry = EntryList.list[name];
        Interface.entryList.removeChild(entry.ref);
        // Shell.log(`File ${entry.name} removed.`);
        delete EntryList.list[name];
    }

    static get values() {
        return Object.values(EntryList.list);
    }
}
