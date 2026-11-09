import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active
    property bool hasToggle
    property alias checked: toggle.checked

    signal toggled(checked: bool)

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: iconLabel.implicitHeight + Tokens.padding.small * 2

            radius: Tokens.rounding.full
            color: root.active ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: iconLabel

                anchors.centerIn: parent
                animate: true
                text: root.icon
                color: root.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.medium
                fill: root.active ? 1 : 0

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text
                animate: true
                text: root.subtitle
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        StyledSwitch {
            id: toggle

            visible: root.hasToggle
            onToggled: root.toggled(checked)
        }
    }
}
