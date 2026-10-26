pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.utils

Searcher {
    id: root

    signal editRequested(entry: DesktopEntry)

    property bool editingDesktop: false

    readonly property string applicationsHome: `${Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`}/applications`

    function requestEdit(entry: DesktopEntry): void {
        root.editRequested(entry);
    }

    function desktopSearchDirs(): var {
        const home = Quickshell.env("HOME");
        const dataHome = Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`;
        return [
            `${dataHome}/applications`,
            `${dataHome}/flatpak/exports/share/applications`,
            `/var/lib/flatpak/exports/share/applications`,
            `/usr/local/share/applications`,
            `/usr/share/applications`
        ];
    }

    function desktopFileName(id: string): string {
        return id.endsWith(".desktop") ? id : `${id}.desktop`;
    }

    function localOverridePath(id: string): string {
        return `${root.applicationsHome}/${root.desktopFileName(id)}`;
    }

    function readDesktopFile(path: string): string {
        if (!path)
            return "";
        io.path = path;
        // text() respects blockAllReads — do not trust io.loaded after path churn
        try {
            return io.text() || "";
        } catch (e) {
            return "";
        }
    }

    function hasLocalOverride(id: string): bool {
        return root.readDesktopFile(root.localOverridePath(id)).length > 0;
    }

    function resolveDesktopPath(id: string): string {
        const name = root.desktopFileName(id);
        for (const dir of root.desktopSearchDirs()) {
            const path = `${dir}/${name}`;
            if (root.readDesktopFile(path).length > 0)
                return path;
        }
        return "";
    }

    function setDesktopKey(text: string, key: string, value: string): string {
        const line = `${key}=${value}`;
        const pat = new RegExp(`^${key.replace(/[[\]]/g, "\\$&")}=.*$`, "m");
        if (pat.test(text))
            return text.replace(pat, line);
        // Match [Desktop Entry] with optional \r
        if (/\[Desktop Entry\]\r?\n/.test(text))
            return text.replace(/\[Desktop Entry\]\r?\n/, m => `${m}${line}\n`);
        return `[Desktop Entry]\n${line}\n${text}`;
    }

    function saveDesktopMetadata(id: string, name: string, comment: string, icon: string): bool {
        const dest = root.localOverridePath(id);
        const src = root.resolveDesktopPath(id);
        if (!src) {
            console.warn(`Apps: no .desktop found for ${id}`);
            return false;
        }

        // Ensure a writable override under ~/.local/share/applications
        if (src !== dest) {
            if (!CUtils.copyFile(Qt.resolvedUrl(src), Qt.resolvedUrl(dest), true)) {
                console.warn(`Apps: failed to copy ${src} -> ${dest}`);
                return false;
            }
        }

        let text = root.readDesktopFile(dest);
        if (!text.length) {
            console.warn(`Apps: cannot read override ${dest}`);
            return false;
        }

        if (name !== undefined && name !== null)
            text = root.setDesktopKey(root.setDesktopKey(root.setDesktopKey(text, "Name", name), "Name[es]", name), "Name[es_ES]", name);
        if (comment !== undefined && comment !== null)
            text = root.setDesktopKey(root.setDesktopKey(root.setDesktopKey(text, "Comment", comment), "Comment[es]", comment), "Comment[es_ES]", comment);
        if (icon !== undefined && icon !== null)
            text = root.setDesktopKey(text, "Icon", icon);

        io.path = dest;
        io.setText(text);
        Quickshell.execDetached(["update-desktop-database", root.applicationsHome]);
        return true;
    }

    function resetDesktopOverride(id: string): bool {
        const path = root.localOverridePath(id);
        if (!root.hasLocalOverride(id))
            return false;
        const ok = CUtils.deleteFile(Qt.resolvedUrl(path));
        if (ok)
            Quickshell.execDetached(["update-desktop-database", root.applicationsHome]);
        return ok;
    }

    function toggleFavourite(id: string): void {
        const apps = GlobalConfig.launcher.favouriteApps;
        if (Strings.testRegexList(apps, id)) {
            // Drop exact id and any ^...$ regex entry that matches this app
            GlobalConfig.launcher.favouriteApps = apps.filter(a => {
                if (a === id)
                    return false;
                if (/^\^.*\$$/.test(a)) {
                    try {
                        return !(new RegExp(a).test(id));
                    } catch (e) {
                        return true;
                    }
                }
                return true;
            });
        } else {
            GlobalConfig.launcher.favouriteApps = [...apps, id];
        }
    }

    function isFavourite(id: string): bool {
        return Strings.testRegexList(GlobalConfig.launcher.favouriteApps, id);
    }

    function hideFromLauncher(id: string): void {
        const apps = GlobalConfig.launcher.hiddenApps;
        if (!Strings.testRegexList(apps, id))
            GlobalConfig.launcher.hiddenApps = [...apps, id];
    }

    function launch(entry: DesktopEntry): void {
        appDb.incrementFrequency(entry.id);

        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: [...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
    }

    function search(search: string): var {
        const prefix = GlobalConfig.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: GlobalConfig.launcher.useFuzzy.apps

    FileView {
        id: io

        printErrors: false
        preload: false
        blockAllReads: true
        blockWrites: true // sync write so path isn't reused before flush
    }

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id))
    }
}
