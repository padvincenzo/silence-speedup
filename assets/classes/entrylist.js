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

export default class EntryList {
    static list = {}
    static canImport = true

    static import(urls) {
        if (urls == undefined || urls == null)
            return 0

        if (!EntryList.canImport)
            return 0

        let len = urls.length
        if (len == 0)
            return 0

        let c = 0

        for (var i = 0; i < len; i++) {
            let url = urls[i].toString()
            let name = Entry.getNameFromUrl(url)
            let extension = Entry.getExtensionFromName(name)
            if (Entry.isExtensionValid(extension)) {
                if (EntryList.list.hasOwnProperty(name)) {
                    Shell.log(`Cannot load ${name}: file name already exists.`)
                } else {
                    var entry = new Entry(url, name, extension)
                    EntryList.list[name] = entry
                    c++
                }
            }
        }

        return c
    }

    static remove(name) {
        var entry = EntryList.list[name]
        Interface.entryList.removeChild(entry.ref)
        // Shell.log(`File ${entry.name} removed.`)
        delete EntryList.list[name]
    }

    static get values() {
        return Object.values(EntryList.list)
    }
}
