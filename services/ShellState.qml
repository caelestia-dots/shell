pragma Singleton

import QtQuick
import Quickshell
import qs.components
import qs.services

Singleton {
    property var states: new Map()

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

    function componentsFor(screen: ShellScreen): Components {
        for (const c of components.instances)
            if (c.modelData === screen)
                return c;
        return null;
    }

    function componentForActive(): Components {
        const mon = Hypr.focusedMonitor;
        for (const c of components.instances)
            if (Hypr.monitorFor(c.modelData) === mon)
                return c;
        return null;
    }

    Variants {
        id: components

        model: Screens.screens

        Components {}
    }

    component Components: QtObject {
        required property ShellScreen modelData

        property var rootWindow
        property var interactionWrapper
        property var bar
        property var panels
    }

    component ComponentRef: QtObject {
        required property ShellScreen screen
        required property string slot
        required property var component

        readonly property QtObject target: ShellState.componentsFor(screen)

        onTargetChanged: {
            if (target)
                target[slot] = component;
        }
        Component.onDestruction: {
            if (target && target[slot] === component)
                target[slot] = null;
        }
    }
}
