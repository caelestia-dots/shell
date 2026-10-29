pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var sessions
    property bool tracked
    property int maxItems: 4
    property string switchIcon

    signal switchRequested

    readonly property real rowsHeight: maxItems * 44 + (maxItems - 1) * Tokens.spacing.small

    implicitHeight: col.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "history"
                color: Colours.palette.m3primary
                fill: 1
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Recent sessions")
                font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
            }

            IconButton {
                visible: root.switchIcon.length > 0
                Layout.topMargin: -Tokens.padding.extraSmall
                Layout.bottomMargin: -Tokens.padding.extraSmall
                type: IconButton.Text
                icon: root.switchIcon
                onClicked: root.switchRequested()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.rowsHeight
            visible: root.sessions.length === 0

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "timer_off"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.tracked ? Tr.tr("No sessions recorded yet") : Tr.tr("Install Non-Steam Playtimes (Millennium) to track sessions")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3outline
                    wrapMode: Text.WordWrap
                }
            }
        }

        Repeater {
            model: root.sessions.slice(0, root.maxItems)

            RowLayout {
                id: row

                required property var modelData
                required property int index

                readonly property date startDate: new Date(modelData.start * 1000)
                readonly property int minutes: Math.round((modelData.end - modelData.start) / 60)

                Layout.fillWidth: true
                implicitHeight: 44
                spacing: Tokens.spacing.medium

                opacity: 0
                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: row.index * 50
                        }
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                StyledRect {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: Tokens.rounding.medium
                    color: row.index === 0 ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest

                    Column {
                        anchors.centerIn: parent
                        spacing: -2

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Tr.formatDateTime(row.startDate, "d")
                            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            color: row.index === 0 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Tr.formatDateTime(row.startDate, "MMM")
                            font: Tokens.font.label.small
                            color: row.index === 0 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.formatDateTime(row.startDate, "dddd")
                        font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: `${Tr.formatDateTime(row.startDate, "HH:mm")} – ${row.modelData.live ? Tr.tr("now") : Tr.formatDateTime(new Date(row.modelData.end * 1000), "HH:mm")}`
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    implicitWidth: durationRow.implicitWidth + Tokens.padding.small * 2
                    implicitHeight: 24
                    radius: Tokens.rounding.full
                    color: row.modelData.live ? Colours.palette.m3tertiaryContainer : Colours.palette.m3secondaryContainer

                    RowLayout {
                        id: durationRow

                        anchors.centerIn: parent
                        spacing: 2

                        MaterialIcon {
                            visible: !!row.modelData.live
                            text: "play_arrow"
                            fill: 1
                            color: Colours.palette.m3onTertiaryContainer
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: Steam.formatPlaytime(row.minutes)
                            font: Tokens.font.label.builders.small.weight(Font.DemiBold).build()
                            color: row.modelData.live ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }
    }
}
