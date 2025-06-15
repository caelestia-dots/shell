pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/config"
import Quickshell
import QtQuick

Scope {
    id: root

    required property ShellScreen screen
    required property Item bar

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.bar.implicitWidth
        implicitHeight: 0
    }

    ExclusionZone {
        anchors.top: true
        implicitWidth: 0
    }

    ExclusionZone {
        anchors.right: true
        implicitHeight: 0
    }

    ExclusionZone {
        anchors.bottom: true
        implicitWidth: 0

    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: BorderConfig.thickness
    }
}
