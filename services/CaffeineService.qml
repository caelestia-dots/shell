pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.config

Singleton {
    id: root

    property bool active: matchCount > 0 && appPatterns.length > 0
    property int matchCount: 0
    property var appPatterns: []

    function updateAppPatterns(): void {
        if (!Config.launcher.caffeineApps || Config.launcher.caffeineApps.length === 0) {
            appPatterns = [];
            return;
        }
        const patterns = [];
        for (const app of Config.launcher.caffeineApps) {
            const lower = app.toLowerCase();
            patterns.push({
                full: lower,
                dotSuffix: lower.includes('.') ? lower.split('.').pop() : null,
                dashSuffix: lower.includes('-') ? lower.split('-').pop() : null
            });
        }
        appPatterns = patterns;
    }

    function matchesAnyPattern(windowClass: string): bool {
        for (const pattern of appPatterns) {
            if (windowClass.includes(pattern.full)) {
                return true;
            }
            if (pattern.dotSuffix && windowClass.includes(pattern.dotSuffix)) {
                return true;
            }
            if (pattern.dashSuffix && windowClass.includes(pattern.dashSuffix)) {
                return true;
            }
        }
        return false;
    }

    onActiveChanged: IdleInhibitor.enabled = active

    Component.onCompleted: updateAppPatterns()

    Instantiator {
        id: windowTracker

        model: Hypr.toplevels

        delegate: QtObject {
            required property var modelData

            readonly property string windowClass: (modelData?.lastIpcObject?.class ?? "").toLowerCase()
            readonly property bool isValid: modelData !== null && !modelData.closed
            readonly property bool matches: isValid && root.matchesAnyPattern(windowClass)

            onMatchesChanged: root.matchCount += matches ? 1 : -1
            Component.onCompleted: {
                if (matches) {
                    root.matchCount++;
                }
            }
            Component.onDestruction: {
                if (matches) {
                    root.matchCount--;
                }
            }
        }
    }

    Connections {
        function onCaffeineAppsChanged(): void {
            root.matchCount = 0;
            root.updateAppPatterns();
        }

        target: Config.launcher
    }
}
