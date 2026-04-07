pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property var panels

    readonly property bool shouldBeActive: visibilities.launcher && Config.launcher.enabled
    property string pendingSearchText: ""
    property bool _showHideTransition: false

    readonly property var currentClipboardItem: {
        const list = content.item?.list?.currentList; // qmllint disable missing-property
        if (!list)
            return null;

        if (list.lastInteraction === "hover" && list.hoveredItem) {
            return list.hoveredItem;
        }
        return list.currentItem;
    }

    readonly property bool showingClipboard: content.item?.list?.showClipboard ?? false // qmllint disable missing-property

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 - Appearance.spacing.large;
        if (visibilities.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    Component.onCompleted: LauncherWrappers.register(root.screen, root)

    onMaxHeightChanged: timer.start()

    visible: height > 0
    implicitWidth: content.implicitWidth
    implicitHeight: shouldBeActive ? content.implicitHeight : 0

    onShouldBeActiveChanged: {
        _showHideTransition = true;
        if (shouldBeActive) {
            timer.stop();
            content.active = Qt.binding(() => root.shouldBeActive || root.visible);
            content.visible = true;
        }
    }

    Behavior on implicitHeight {
        enabled: root._showHideTransition

        Anim {
            duration: root.shouldBeActive ? Appearance.anim.durations.expressiveDefaultSpatial : Appearance.anim.durations.normal
            easing.bezierCurve: root.shouldBeActive ? Appearance.anim.curves.expressiveDefaultSpatial : Appearance.anim.curves.emphasized
            onRunningChanged: {
                if (!running)
                    root._showHideTransition = false;
            }
        }
    }

    Connections {
        function onEnabledChanged(): void {
            timer.start();
        }

        function onMaxShownChanged(): void {
            timer.start();
        }

        target: Config.launcher
    }

    Connections {
        function onValuesChanged(): void {
            if (DesktopEntries.applications.values.length < Config.launcher.maxShown)
                timer.start();
        }

        target: DesktopEntries.applications
    }

    Timer {
        id: timer

        interval: Appearance.anim.durations.extraLarge
        onRunningChanged: {
            if (running && !root.shouldBeActive) {
                content.visible = false;
                content.active = true;
            } else if (!running) {
                content.active = Qt.binding(() => root.shouldBeActive || root.visible);
                content.visible = true;
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
            screen: root.screen
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight
            initialSearchText: root.pendingSearchText

            Component.onCompleted: {
                root.pendingSearchText = "";
            }
        }
    }
}
