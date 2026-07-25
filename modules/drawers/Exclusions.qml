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
    required property EdgeGeometry geometry

    ExclusionZone {
        anchors.left: true
        hasBar: root.geometry.barOnLeft
    }

    ExclusionZone {
        anchors.top: true
        hasBar: root.geometry.barOnTop
    }

    ExclusionZone {
        anchors.right: true
    }

    ExclusionZone {
        anchors.bottom: true
        hasBar: root.geometry.barOnBottom
    }

    component ExclusionZone: StyledWindow {
        property bool hasBar

        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: hasBar ? root.bar.exclusiveZone : contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
