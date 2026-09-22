pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool sidebarOrSessionVisible

    property bool hovered
    readonly property Brightness.Monitor monitor: Brightness.getMonitorForScreen(root.screen)
    readonly property bool shouldBeActive: screenState.osd && Config.osd.enabled && !(screenState.utilities && Config.utilities.enabled)
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarOffset: sidebarOrSessionVisible ? 12 : 0

    property real volume
    property bool muted
    property real sourceVolume
    property bool sourceMuted
    property real brightness

    function show(): void {
        screenState.osd = true;
        timer.restart();
    }

    Component.onCompleted: {
        volume = Audio.volume;
        muted = Audio.muted;
        sourceVolume = Audio.sourceVolume;
        sourceMuted = Audio.sourceMuted;
        brightness = root.monitor?.brightness ?? 0;
    }

    property real edgeOffset: 0

    readonly property string placementStr: {
        const allowed = ["top", "top-left", "top-right", "bottom", "bottom-left", "bottom-right", "left", "right"];
        const val = Config.osd.placement || "";
        return allowed.includes(val) ? val : "right";
    }
    readonly property string edge: placementStr.split("-")[0]
    readonly property string align: placementStr.split("-")[1] || "center"
    readonly property bool isHorizontal: edge === "top" || edge === "bottom"

    visible: offsetScale < 1
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    width: implicitWidth
    height: implicitHeight

    readonly property real baseX: {
        if (edge === "left")
            return sidebarOffset;
        if (edge === "right")
            return parent.width - width - sidebarOffset - edgeOffset;
        if (align === "left" || align === "start")
            return sidebarOffset;
        if (align === "right" || align === "end")
            return parent.width - width - sidebarOffset;
        return (parent.width - width) / 2;
    }

    readonly property real baseY: {
        if (edge === "top")
            return sidebarOffset;
        if (edge === "bottom")
            return parent.height - height - sidebarOffset;
        if (align === "top" || align === "start")
            return sidebarOffset;
        if (align === "bottom" || align === "end")
            return parent.height - height - sidebarOffset;
        return (parent.height - height) / 2;
    }

    readonly property real animOffsetX: {
        if (edge === "left")
            return (-width - 5 - sidebarOffset) * offsetScale;
        if (edge === "right")
            return (width + 5 + sidebarOffset + edgeOffset) * offsetScale;
        return 0;
    }

    readonly property real animOffsetY: {
        if (edge === "top")
            return (-height - 5 - sidebarOffset) * offsetScale;
        if (edge === "bottom")
            return (height + 5 + sidebarOffset) * offsetScale;
        return 0;
    }

    x: baseX + animOffsetX
    y: baseY + animOffsetY

    Connections {
        function onMutedChanged(): void {
            root.show();
            root.muted = Audio.muted;
        }

        function onVolumeChanged(): void {
            root.show();
            root.volume = Audio.volume;
        }

        function onSourceMutedChanged(): void {
            root.show();
            root.sourceMuted = Audio.sourceMuted;
        }

        function onSourceVolumeChanged(): void {
            root.show();
            root.sourceVolume = Audio.sourceVolume;
        }

        target: Audio
    }

    Connections {
        function onBrightnessChanged(): void {
            root.show();
            root.brightness = root.monitor?.brightness ?? 0;
        }

        target: root.monitor
    }

    Timer {
        id: timer

        interval: root.Config.osd.hideDelay
        onTriggered: {
            if (!root.hovered)
                root.screenState.osd = false;
        }
    }

    Loader {
        id: content

        asynchronous: true
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            monitor: root.monitor
            screenState: root.screenState
            volume: root.volume
            muted: root.muted
            sourceVolume: root.sourceVolume
            sourceMuted: root.sourceMuted
            brightness: root.brightness
            isHorizontal: root.isHorizontal
            edge: root.edge
        }
    }
}
