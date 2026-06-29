import QtQuick
import Caelestia.Config
import qs.components
import qs.services

TextFieldBase {
    id: root

    readonly property alias bg: bg
    readonly property alias searchIcon: searchIcon
    readonly property alias clearIcon: clearIcon

    leftPadding: searchIcon.width + searchIcon.anchors.leftMargin + Tokens.spacing.medium
    rightPadding: clearIcon.width + clearIcon.anchors.rightMargin + Tokens.spacing.medium
    topPadding: Tokens.padding.large
    bottomPadding: Tokens.padding.large

    onPressed: {
        if (!stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }

    background: StyledRect {
        id: bg

        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        StateLayer {
            id: stateLayer

            cursorShape: Qt.IBeamCursor
            disabled: root.activeFocus
            manualPressOverride: tapHandler.pressed
            onClicked: root.focus = true
        }
    }

    StyledText {
        id: placeholder

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.leftPadding

        text: root.placeholderText
        color: root.placeholderTextColor
        font: root.font

        opacity: root.text ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    MaterialIcon {
        id: searchIcon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.large

        text: "search"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.builders.medium.scale(0.9).build()
    }

    IconButton {
        id: clearIcon

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Tokens.padding.medium

        icon: "clear"
        type: IconButton.Text
        radius: Tokens.rounding.full
        radiusMorph: false
        enabled: root.text
        stateLayer.hoverEnabled: enabled
        onClicked: root.clear()

        opacity: root.text ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    TapHandler {
        id: tapHandler
    }
}
