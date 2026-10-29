pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.State
import qs.components.containers
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar

    readonly property int frameZone: RuntimeState.gameMode ? 0 : Config.border.thickness

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.bar.exclusiveZone
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: root.frameZone
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: root.frameZone
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: root.frameZone
    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
