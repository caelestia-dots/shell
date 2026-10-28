import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.images
import qs.services

RowLayout {
    id: root

    readonly property color stateColour: {
        if (Steam.profile?.gameExtraInfo)
            return Colours.palette.m3tertiary;
        if ((Steam.profile?.personaState ?? 0) > 0)
            return Colours.palette.m3primary;
        return Colours.palette.m3outline;
    }

    spacing: Tokens.spacing.large

    Item {
        implicitWidth: 56
        implicitHeight: 56

        ClipRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: Colours.palette.m3surfaceContainerHighest

            FadeImage {
                anchors.fill: parent
                source: Steam.profile?.avatarUrl ?? ""
            }
        }

        StyledRect {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            implicitWidth: 16
            implicitHeight: 16
            radius: Tokens.rounding.full
            color: Colours.palette.m3surface

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 10
                implicitHeight: 10
                radius: Tokens.rounding.full
                color: root.stateColour
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: Steam.profile?.personaName ?? ""
            font: Tokens.font.body.builders.large.size(24).weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            text: Steam.profile?.gameExtraInfo ? Tr.tr("Playing %1").arg(Steam.profile.gameExtraInfo) : Steam.personaStateLabel
            font: Tokens.font.body.small
            color: Steam.profile?.gameExtraInfo ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        visible: Steam.steamLevel > 0
        text: Tr.tr("Level")
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurfaceVariant
    }

    MaterialShape {
        Layout.alignment: Qt.AlignVCenter
        visible: Steam.steamLevel > 0
        implicitSize: 52
        shape: MaterialShape.Cookie9Sided
        color: Colours.palette.m3secondaryContainer

        StyledText {
            anchors.centerIn: parent
            text: Steam.steamLevel
            font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSecondaryContainer
        }
    }

    Item {
        implicitWidth: refreshBtn.implicitWidth
        implicitHeight: refreshBtn.implicitHeight

        IconButton {
            id: refreshBtn

            anchors.centerIn: parent
            type: IconButton.Text
            icon: "refresh"
            opacity: Steam.loading ? 0 : 1
            disabled: Steam.loading
            onClicked: Steam.reload()

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        CircularIndicator {
            anchors.centerIn: parent
            implicitSize: refreshBtn.implicitHeight - Tokens.padding.small
            running: Steam.loading
            opacity: Steam.loading ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
