pragma Singleton

import Quickshell
import Caelestia.Config

Singleton {
    readonly property var all: [Emojis.source, Kaomoji.source, Symbols.source]

    // The picker that's open for the given launcher text, if any
    function forText(text: string): var {
        const prefix = GlobalConfig.launcher.actionPrefix;
        return all.find(s => text.startsWith(`${prefix}${s.mode} `)) ?? null;
    }
}
