import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + (IdleInhibitor.enabled ? activeChip.implicitHeight + activeChip.anchors.topMargin : 0) + Tokens.padding.large * 2

    radius: Tokens.rounding.normal
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.smaller * 2

            radius: Tokens.rounding.full
            color: IdleInhibitor.enabled ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "coffee"
                color: IdleInhibitor.enabled ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                font.pointSize: Tokens.font.size.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Keep Awake")
                font.pointSize: Tokens.font.size.normal
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: IdleInhibitor.enabled ? qsTr("Preventing sleep mode") : qsTr("Normal power management")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.small
                elide: Text.ElideRight
            }
        }

        StyledSwitch {
            checked: IdleInhibitor.enabled
            onToggled: IdleInhibitor.enabled = checked
        }
    }

    Loader {
        id: activeChip

        asynchronous: true
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: Tokens.spacing.larger
        anchors.bottomMargin: IdleInhibitor.enabled ? Tokens.padding.large : -implicitHeight
        anchors.leftMargin: Tokens.padding.large

        opacity: IdleInhibitor.enabled ? 1 : 0
        scale: IdleInhibitor.enabled ? 1 : 0.5

        Component.onCompleted: active = Qt.binding(() => opacity > 0)

        sourceComponent: StyledRect {
            implicitWidth: activeText.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: activeText.implicitHeight + Tokens.padding.small * 2

            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            StyledText {
                id: activeText

                anchors.centerIn: parent
                text: qsTr("Active since %1").arg(Qt.formatTime(IdleInhibitor.enabledSince, GlobalConfig.services.useTwelveHourClock ? "hh:mm a" : "hh:mm"))
                color: Colours.palette.m3onPrimary
                font.pointSize: Math.round(Tokens.font.size.small * 0.9)
            }
        }

        Behavior on anchors.bottomMargin {
            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
}
