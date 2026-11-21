pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config

Singleton {
    function exec(command: list<string>, workingDirectory = ""): void {
        if (!command.length)
            return;

        Quickshell.execDetached({
            command: [...GlobalConfig.general.apps.launchPrefix, ...command],
            workingDirectory
        });
    }

    function openUrl(url: string): void {
        if (url.length === 0)
            return;

        // Use xdg-open when a prefix is configured so it applies to URL handlers.
        if (GlobalConfig.general.apps.launchPrefix.length)
            exec(["xdg-open", url]);
        else
            Qt.openUrlExternally(url);
    }
}
