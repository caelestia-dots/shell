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

    ExclusionZone {
        anchors.left: true
        exclusiveZone: contentItem.Config.bar.alignment === "left" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: contentItem.Config.bar.alignment === "top" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: contentItem.Config.bar.alignment === "right" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: contentItem.Config.bar.alignment === "bottom" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
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