import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

StyledRect {
    id: root

    required property NexusState nState

    implicitHeight: searchLayout.implicitHeight + Tokens.padding.medium * 2

    radius: Tokens.rounding.full
    color: Colours.tPalette.m3surfaceContainerLowest
    border.color: Colours.palette.m3outlineVariant

    Behavior on border.color {
        CAnim {}
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: searchField.focus = true
    }

    RowLayout {
        id: searchLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "search"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        StyledTextField {
            id: searchField

            Layout.fillWidth: true
            Layout.fillHeight: true

            placeholderText: qsTr("Search settings")
            placeholderTextColor: Colours.palette.m3onSurfaceVariant
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.large

            Binding {
                target: root.nState
                property: "searchOpen"
                value: searchField.text.length > 0
            }
        }

        IconButton {
            icon: "close"
            font: Tokens.font.icon.medium
            type: IconButton.Text
            padding: Tokens.padding.extraSmall
            isRound: true
            onClicked: searchField.clear()

            opacity: searchField.text.length > 0 ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
