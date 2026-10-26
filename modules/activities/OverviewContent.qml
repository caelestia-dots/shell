pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ShellScreen screen

    readonly property int activityCount: Math.max(1, Activities.mappedActivities.length)
    // Larger previews: use most of the available width across activities
    readonly property real cardWidth: {
        const sidePad = Tokens.padding.extraLarge * 4;
        const gaps = Tokens.spacing.large * Math.max(0, activityCount - 1);
        const perAct = (width - sidePad - gaps) / activityCount;
        // leave room for activity card padding; prefer ~0.9 of column for the preview
        return Math.min(420, Math.max(220, perAct * 0.72));
    }

    // Same translucent surface + Hyprland blur as shell drawers with Transparency on.
    // No hover tint — it would shift the whole backdrop when moving over cards/windows.
    StyledRect {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3surface, Colours.transparency.base)

        MouseArea {
            anchors.fill: parent
            onClicked: Activities.closeOverview()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Tokens.padding.extraLarge * 2, row.implicitWidth)
        spacing: Tokens.spacing.large

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Activities overview")
                font: Tokens.font.headline.small
                color: Colours.palette.m3onSurface
            }

            IconButton {
                icon: "close"
                type: IconButton.Text
                isRound: true
                onClicked: Activities.closeOverview()
            }
        }

        Row {
            id: row

            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.large

            Repeater {
                model: Activities.mappedActivities

                StyledRect {
                    id: actCard

                    required property var modelData

                    width: root.cardWidth + Tokens.padding.large * 2
                    height: actCol.implicitHeight + Tokens.padding.large * 2
                    radius: Tokens.rounding.extraLarge
                    color: Colours.tPalette.m3surfaceContainer

                    ActivityColumn {
                        id: actCol

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.padding.large
                        screen: root.screen
                        activity: actCard.modelData
                        cardWidth: root.cardWidth
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Tr.tr("Click a desktop to switch · Drag windows to move · Esc to close")
            color: Colours.palette.m3outline
            font: Tokens.font.label.medium
        }
    }

    // Reparented window previews live here while dragging between desktops
    Item {
        id: dragLayer

        anchors.fill: parent
        z: 1000
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Activities.closeOverview();
            event.accepted = true;
        }
    }

    Component.onCompleted: {
        Activities.overviewDragLayer = dragLayer;
        forceActiveFocus();
    }

    Component.onDestruction: {
        if (Activities.overviewDragLayer === dragLayer)
            Activities.overviewDragLayer = null;
    }
}
