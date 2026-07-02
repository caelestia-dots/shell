pragma Singleton

import Quickshell
import qs.components
import qs.services

Singleton {
    property var states: new Map()
    property var bars: new Map()

    function anySidebarOpen(): bool {
        return [...states.values()].some(s => s.sidebar);
    }

    function register(screen: ShellScreen, state: ScreenState): void {
        states.set(Hypr.monitorFor(screen), state);
    }

    function forScreen(screen: ShellScreen): ScreenState {
        return states.get(Hypr.monitorFor(screen));
    }

    function forActive(): ScreenState {
        return states.get(Hypr.focusedMonitor);
    }
}
