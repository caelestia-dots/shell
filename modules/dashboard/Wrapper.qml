pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    readonly property FileDialog facePicker: FileDialog {
        title: Tr.tr("Select a profile picture")
        filterLabel: Tr.tr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                // TRANSLATORS: %1 = a file path
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, Tr.tr("Profile picture changed"), Tr.tr("Profile picture changed to %1").arg(Paths.shortenHome(path))]);
            else
                // TRANSLATORS: %1 = a file path
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", Tr.tr("Unable to change profile picture"), Tr.tr("Failed to change profile picture to %1").arg(Paths.shortenHome(path))]);
        }
    }

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1


    readonly property string placementStr: {
        const allowed = ["top", "top-left", "top-right", "bottom", "bottom-left", "bottom-right"];
        const val = Config.dashboard.placement || "";
        return allowed.includes(val) ? val : "top";
    }
    readonly property string edge: placementStr.split("-")[0]
    readonly property string align: placementStr.split("-")[1] || "center"

    readonly property real offsetX: 0
    readonly property real offsetY: edge === "top" ? (-implicitHeight - 5) * offsetScale : (implicitHeight + 5) * offsetScale

    readonly property real baseX: {
        if (align === "left" || align === "start") return 0;
        if (align === "right" || align === "end") return parent.width - implicitWidth;
        return (parent.width - implicitWidth) / 2;
    }

    readonly property real baseY: edge === "top" ? 0 : parent.height - implicitHeight

    x: baseX + offsetX
    y: baseY + offsetY
    visible: offsetScale < 1
    
    implicitHeight: content.implicitHeight || 0
    implicitWidth: content.implicitWidth || 854
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content
        anchors.centerIn: parent
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            facePicker: root.facePicker

            tabsAtBottom: root.placementStr.includes("bottom")
        }
    }
}
