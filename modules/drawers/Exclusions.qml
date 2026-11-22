pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.services

Scope {
    id: root

    required property ShellScreen screen

    ExclusionZone {
        anchors.left: true
    }

    // Windows stay clear of whichever island is in use: the notch's resting pill (34 px, not its
    // taller alert states, so windows don't jump) or the dock row (60 px). The notch's zone is 5 px
    // short so Hyprland's 10 px gap under it reads as half
    ExclusionZone {
        anchors.top: true
        exclusiveZone: contentItem.Config.border.thickness + (!Dock.mode && !NotchSettings.minimal ? 34 * NotchSettings.scale - 10: 0)
    }

    ExclusionZone {
        anchors.right: true
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: contentItem.Config.border.thickness + (Dock.mode ? 60 : 0)
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
