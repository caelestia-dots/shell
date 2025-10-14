pragma ComponentBehavior: Bound

import qs.components.containers
import qs.config
import Quickshell
import QtQuick

Scope {
    id: root

    required property ShellScreen screen
    required property Item bar
    required property int borderThickness

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.bar.exclusiveZone
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: root.borderThickness
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: root.borderThickness
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: root.borderThickness
    }

    component ExclusionZone: StyledWindow {
        required property int exclusiveZone

        screen: root.screen
        name: "border-exclusion"
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
