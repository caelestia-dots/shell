pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property ShellScreen screen
    required property var activity
    required property real cardWidth

    readonly property bool isCurrent: Activities.currentActivity?.id === activity?.id

    spacing: Tokens.spacing.medium

    Item {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight

        RowLayout {
            id: headerRow

            anchors.fill: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: root.activity?.icon || "dashboard"
                color: root.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.fillWidth: true
                text: root.activity?.name ? Tr.trMarked(root.activity.name) : ""
                color: root.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: Tokens.font.title.medium
                elide: Text.ElideRight
            }
        }

        StateLayer {
            anchors.fill: parent
            onClicked: {
                if (root.activity)
                    Activities.focusActivity(root.activity.id);
                Activities.closeOverview();
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        Repeater {
            model: root.activity?.workspaceIds ?? []

            WorkspaceCard {
                required property var modelData

                screen: root.screen
                wsId: modelData
                cardWidth: root.cardWidth
            }
        }
    }
}
