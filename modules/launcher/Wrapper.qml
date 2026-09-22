pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.launcher && Config.launcher.enabled

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    readonly property string placementStr: {
        const allowed = ["top", "center", "bottom"];
        const val = Config.launcher.placement || "";
        return allowed.includes(val) ? val : "bottom";
    }
    readonly property string edge: placementStr

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    implicitWidth: content.implicitWidth || 630
    implicitHeight: content.implicitHeight
    width: implicitWidth
    height: implicitHeight

    visible: offsetScale < 1
    opacity: 1 - offsetScale

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on offsetScale {
        Anim {}
    }

    x: (parent.width - width) / 2
    y: {
        if (edge === "top")
            return (-height - 5) * offsetScale;
        if (edge === "center")
            return (parent.height - height) / 2 + (20 * offsetScale);
        return parent.height - height + ((height + 5) * offsetScale);
    }

    Loader {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        asynchronous: true
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
