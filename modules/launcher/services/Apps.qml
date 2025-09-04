pragma Singleton

import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.LocalStorage

Searcher {
    id: root
    readonly property string dbName: "CaelestiaAppFrequency"
    readonly property string dbVersion: "1.0"
    readonly property string dbDescription: "Stores app launch frequencies"
    readonly property int dbSize: 100000

    property int frequencyVersion: 0
    property var _frequencyData: ({})
    property bool _frequencyDataLoaded: false

    signal appFrequencyChanged(string appId)

    function initializeDatabase() {
        if (_frequencyDataLoaded || DesktopEntries.applications.values.length === 0) {
            return;
        }

        const db = LocalStorage.openDatabaseSync(dbName, dbVersion, dbDescription, dbSize);
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS frequencies(app_id TEXT PRIMARY KEY, count INTEGER)');
        });

        let data = {};
        db.readTransaction(function(tx) {
            const rs = tx.executeSql('SELECT * FROM frequencies');
            for (let i = 0; i < rs.rows.length; i++) {
                let item = rs.rows.item(i);
                data[item.app_id] = item.count;
            }
        });

        for (const app of DesktopEntries.applications.values) {
            if (app.id && !(app.id in data)) {
                data[app.id] = 0;
            }
        }

        _frequencyData = data;
        _frequencyDataLoaded = true;
        frequencyVersion++;
    }

    Timer {
        id: initTimer
        interval: 200
        repeat: true
        running: true
        onTriggered: {
            initializeDatabase();
            if (_frequencyDataLoaded) {
                initTimer.running = false;
            }
        }
    }

    readonly property var appSorter: (a, b) => {
        const countA = _frequencyData[a.id] || 0;
        const countB = _frequencyData[b.id] || 0;
        if (countB !== countA) return countB - countA;
        return a.name.localeCompare(b.name);
    }

    property var _sortedAppsCache: null
    property int _lastFrequencyVersion: -1

    function getSortedApps() {
        if (_sortedAppsCache === null || _lastFrequencyVersion !== frequencyVersion) {
            if (_frequencyDataLoaded) {
                _sortedAppsCache = [...DesktopEntries.applications.values].sort(appSorter);
                _lastFrequencyVersion = frequencyVersion;
            }
        }
        return _sortedAppsCache;
    }

    onFrequencyVersionChanged: {
        if (!_frequencyDataLoaded) return;
        const sortedApps = getSortedApps();
        variants.model = sortedApps;
    }

    function launch(entry: DesktopEntry): void {
        if (entry.id) {
            const appId = entry.id;
            const currentCount = _frequencyData[appId] || 0;
            const newCount = currentCount + 1;
            _frequencyData[appId] = newCount;

            const db = LocalStorage.openDatabaseSync(dbName, dbVersion, dbDescription, dbSize);
            db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO frequencies VALUES(?, ?)', [appId, newCount]);
            });

            frequencyVersion++;
            appFrequencyChanged(appId);
        }

        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["app2unit", "--", ...Config.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["app2unit", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
    }

    function search(search: string): list<var> {
        if (_sortedAppsCache === null || _lastFrequencyVersion !== frequencyVersion) {
            getSortedApps();
        }

        const prefix = Config.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["desc", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["wmClass", "name"];
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

            if (!search.startsWith(`${prefix}t `)) {
                if (!search.trim()) {
                    return _sortedAppsCache || [];
                }
                return query(search).map(e => e.modelData);
            }
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.modelData);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: variants.instances
    useFuzzy: Config.launcher.useFuzzy.apps

    Variants {
        id: variants

        model: []

        QtObject {
            required property DesktopEntry modelData
            readonly property string id: modelData.id
            readonly property string name: modelData.name
            readonly property string desc: modelData.comment
            readonly property string execString: modelData.execString
            readonly property string wmClass: modelData.startupClass
            readonly property string genericName: modelData.genericName
            readonly property string categories: modelData.categories.join(" ")
            readonly property string keywords: modelData.keywords.join(" ")
        }
    }
}
