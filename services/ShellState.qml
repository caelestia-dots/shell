pragma Singleton

import QtQuick
import Quickshell
import qs.components
import qs.services

Singleton {
    function anySidebarOpen(): bool {
        return states.instances.some(s => s.sidebar);
    }

    function forScreen(screen: ShellScreen): ScreenState {
        for (const s of states.instances)
            if (s.modelData === screen)
                return s;
        return null;
    }

    function forActive(): ScreenState {
        const mon = Hypr.focusedMonitor;
        for (const s of states.instances)
            if (Hypr.monitorFor(s.modelData) === mon)
                return s;
        return null;
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
        id: states

        model: Screens.screens

        ScreenState {}
    }

    Variants {
        id: components

        model: Screens.screens

        Components {}
    }

    component Components: QtObject {
        required property ShellScreen modelData

        property var background
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
