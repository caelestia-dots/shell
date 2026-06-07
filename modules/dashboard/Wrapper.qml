pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities
    readonly property bool needsKeyboard: !fireActive && (dashState.timerPanelOpen || ((content.item as Content)?.needsKeyboard ?? false))
    readonly property DashboardState dashState: DashboardState {
        reloadableId: "dashboardState"
    }
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property bool fireActive: TimerService.timerDone || AlarmService.alarmFired
    property bool _wasOpenBeforeFire: false

    onFireActiveChanged: {
        if (fireActive && !_wasOpenBeforeFire && !LockState.locked) {
            _wasOpenBeforeFire = visibilities.dashboard;
            visibilities.dashboard = true;
        }
    }

    Connections {
        target: LockState
        function onLockedChanged(): void {
            if (!LockState.locked && root.fireActive && !root.visibilities.dashboard) {
                root.visibilities.dashboard = true;
            }
        }
    }

    readonly property real nonAnimHeight: !fireActive ? ((content.item as Content)?.nonAnimHeight ?? 0) : 0
    readonly property bool shouldBeActive: (visibilities.dashboard && Config.dashboard.enabled) || fireActive
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: fireActive ? (fireContent.implicitHeight || 400) : (content.implicitHeight)
    implicitWidth: fireActive ? (fireContent.implicitWidth || 800) : (content.implicitWidth || 854)
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.shouldBeActive && !root.fireActive

        sourceComponent: Content {
            visibilities: root.visibilities
            dashState: root.dashState
            facePicker: root.facePicker
        }
    }

    Loader {
        id: fireContent

        anchors.fill: parent

        active: root.fireActive

        sourceComponent: FiringOverlay {
            visibilities: root.visibilities
        }
    }
}
