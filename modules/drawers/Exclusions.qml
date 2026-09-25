pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar

    readonly property string position: bar.position

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.position === "left" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: root.position === "top" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: root.position === "right" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: root.position === "bottom" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
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
