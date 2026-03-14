pragma ComponentBehavior: Bound

import "items"
import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property var panels

    readonly property bool shouldBeActive: visibilities.launcher && Config.launcher.enabled
    property int contentHeight
    property bool animationComplete: false

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 - Appearance.spacing.large;
        if (visibilities.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    onMaxHeightChanged: timer.start()

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            timer.stop();
            hideAnim.stop();
            root.animationComplete = false;
            showAnim.start();
        } else {
            root.requestCloseContextMenu();
            showAnim.stop();
            root.animationComplete = false;
            hideAnim.start();
        }
    }

    SequentialAnimation {
        id: showAnim

        Anim {
            target: root
            property: "implicitHeight"
            to: root.contentHeight
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
        ScriptAction {
            script: {
                root.implicitHeight = Qt.binding(() => content.implicitHeight);
                // Wait one more frame after animation to ensure layout is stable
                Qt.callLater(() => {
                    root.animationComplete = true;
                });
            }
        }
    }

    SequentialAnimation {
        id: hideAnim

        ScriptAction {
            script: root.implicitHeight = root.implicitHeight
        }
        Anim {
            target: root
            property: "implicitHeight"
            to: 0
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Connections {
        target: Config.launcher

        function onEnabledChanged(): void {
            timer.start();
        }

        function onMaxShownChanged(): void {
            timer.start();
        }
    }

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged(): void {
            if (DesktopEntries.applications.values.length < Config.launcher.maxShown)
                timer.start();
        }
    }

    Timer {
        id: timer

        interval: Appearance.anim.durations.extraLarge
        onRunningChanged: {
            if (running && !root.shouldBeActive) {
                content.visible = false;
                content.active = true;
            } else {
                root.contentHeight = Math.min(root.maxHeight, content.implicitHeight);
                content.active = Qt.binding(() => root.shouldBeActive || root.visible);
                content.visible = true;
                if (showAnim.running) {
                    showAnim.stop();
                    showAnim.start();
                }
            }
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        visible: false
        active: false
        Component.onCompleted: timer.start()

        sourceComponent: Content {
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight
            showContextMenuAt: root.showContextMenu
            wrapperRoot: root

            Component.onCompleted: {
                root.contentHeight = implicitHeight;
                Qt.callLater(() => {
                    root.animationComplete = true;
                });
            }
        }
    }

    signal requestShowContextMenu(app: DesktopEntry, clickX: real, clickY: real)
    signal requestCloseContextMenu

    function restoreFocus(): void {
        if (content.item && content.item.searchField) {
            content.item.searchField.forceActiveFocus();
        }
    }

    function showContextMenu(app: DesktopEntry, clickX: real, clickY: real): void {
        if (!app || !root.animationComplete) {
            return;
        }

        if (clickX < 0 || clickX > root.width || clickY < 0 || clickY > root.height) {
            return;
        }

        root.requestShowContextMenu(app, clickX, clickY);
    }
}
