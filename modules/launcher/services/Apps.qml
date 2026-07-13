pragma Singleton

import Quickshell
import Caelestia
import Caelestia.Config
import qs.utils

Searcher {
    id: root

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

    function search(search: string): list<var> {
        const prefix = GlobalConfig.launcher.specialPrefix;

        let newKeys = ["name"];
        let newWeights = [1];
        let skipPrefixSlice = false;

        if (search.startsWith(`${prefix}i `)) {
            newKeys = ["id", "name"];
            newWeights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            newKeys = ["categories", "name"];
            newWeights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            newKeys = ["comment", "name"];
            newWeights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            newKeys = ["execString", "name"];
            newWeights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            newKeys = ["startupClass", "name"];
            newWeights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            newKeys = ["genericName", "name"];
            newWeights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            newKeys = ["keywords", "name"];
            newWeights = [0.9, 0.1];
        } else {
            if (!search.startsWith(`${prefix}t `)) {
                skipPrefixSlice = true;
            }
        }

        if (skipPrefixSlice) {
            return query(search, newKeys, newWeights).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2), newKeys, newWeights).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: GlobalConfig.launcher.useFuzzy.apps

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id))
    }
}
