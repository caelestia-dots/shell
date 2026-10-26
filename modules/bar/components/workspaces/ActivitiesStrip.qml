pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Column {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    spacing: Tokens.spacing.small

    Repeater {
        model: Activities.mappedActivities

        ActivityPill {
            required property var modelData

            screen: root.screen
            fullscreen: root.fullscreen
            activity: modelData
        }
    }
}
