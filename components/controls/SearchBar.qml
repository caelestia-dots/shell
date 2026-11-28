import QtQuick
import Caelestia.Config
import qs.components
import qs.services

TextFieldBase {
    id: root

    readonly property alias bg: bg
    readonly property alias searchIcon: searchIcon
    readonly property alias clearIcon: clearIcon

    property string crumbText: ""
    readonly property int crumbPad: crumb.visible ? crumb.width + Tokens.spacing.medium : 0

    signal crumbClicked

    leftPadding: searchIcon.width + searchIcon.anchors.leftMargin + Tokens.spacing.medium + root.crumbPad
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

    StyledRect {
        id: crumb

        visible: root.crumbText !== ""
        anchors.left: searchIcon.right
        anchors.leftMargin: Tokens.spacing.medium
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Math.min(crumbLabel.implicitWidth + Tokens.padding.medium * 2, parent.width * 0.5)
        implicitHeight: crumbLabel.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer

        StyledText {
            id: crumbLabel

            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - Tokens.padding.medium * 2)
            elide: Text.ElideRight

            text: root.crumbText
            color: Colours.palette.m3onSecondaryContainer
            font: Tokens.font.body.small
        }

        StateLayer {
            radius: Tokens.rounding.full
            color: Colours.palette.m3onSecondaryContainer

            onClicked: root.crumbClicked()
        }
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
