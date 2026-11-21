pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config

Singleton {
    function prefix(): list<string> {
        // Missing on a plugin built before this setting existed.
        return GlobalConfig.general.apps.launchPrefix ?? [];
    }

    function exec(command: list<string>, workingDirectory: string): void {
        if (command.length === 0)
            return;

        const prefixed = [...prefix(), ...command];
        if (workingDirectory.length > 0)
            Quickshell.execDetached({
                command: prefixed,
                workingDirectory: workingDirectory
            });
        else
            Quickshell.execDetached(prefixed);
    }

    function openUrl(url: string): void {
        if (url.length === 0)
            return;

        // Qt.openUrlExternally spawns the opener as a child of the shell, and a
        // handler that is not already running (e.g. a browser) inherits the
        // shell's cgroup. A prefix can only wrap a command we run ourselves, so
        // use xdg-open then. Without a prefix keep Qt's own opener and fallbacks.
        if (prefix().length > 0)
            exec(["xdg-open", url], "");
        else
            Qt.openUrlExternally(url);
    }
}
