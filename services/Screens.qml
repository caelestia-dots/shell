pragma Singleton

import Quickshell
import qs.config
import qs.utils

Singleton {
    id: root

    readonly property list<ShellScreen> screens: {
        const excluded = Config.general.excludedScreens;
        if (excluded.length === 0)
            return Quickshell.screens;
        return Quickshell.screens.filter(s => !Strings.testRegexList(excluded, s.name));
    }

    function isExcluded(screen: ShellScreen): bool {
        return Strings.testRegexList(Config.general.excludedScreens, screen.name);
    }
}
