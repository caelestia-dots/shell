import "../effects"
import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

Slider {
    id: root

    required property string icon
    property bool isHorizontal
    property real oldValue
    property bool initialized

    orientation: isHorizontal ? Qt.Horizontal : Qt.Vertical

    background: StyledRect {
        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

        StyledRect {
            x: 0
            y: root.isHorizontal ? 0 : root.handle.y

            implicitWidth: root.isHorizontal ? root.handle.x + root.handle.width : parent.width
            implicitHeight: root.isHorizontal ? parent.height : parent.height - y

            color: Colours.palette.m3secondary
            radius: parent.radius
        }
    }

    handle: Item {
        id: handle

        property alias moving: icon.moving

        x: root.isHorizontal ? root.visualPosition * (root.availableWidth - width) : 0
        y: root.isHorizontal ? 0 : root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.isHorizontal ? root.height : root.width
        implicitHeight: root.isHorizontal ? root.height : root.width

        Elevation {
            anchors.fill: parent
            radius: rect.radius
            level: handleInteraction.containsMouse ? 2 : 1
        }

        StyledRect {
            id: rect

            anchors.fill: parent

            color: Colours.palette.m3inverseSurface
            radius: Tokens.rounding.full

            MouseArea {
                id: handleInteraction

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }

            MaterialIcon {
                id: icon

                property bool moving

                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: moving ? Math.round(root.value * 100) : root.icon
                color: Colours.palette.m3inverseOnSurface
                font: moving ? Tokens.font.body.small : Tokens.font.icon.medium

                Behavior on moving {
                    SequentialAnimation {
                        Anim {
                            target: icon
                            property: "scale"
                            to: 0.3
                            duration: Tokens.anim.durations.small / 2
                            easing: Tokens.anim.standardAccel
                        }
                        PropertyAction {}
                        Anim {
                            target: icon
                            property: "scale"
                            to: 1
                            duration: Tokens.anim.durations.normal / 2
                            easing: Tokens.anim.standardDecel
                        }
                    }
                }
            }
        }
    }

    onPressedChanged: handle.moving = pressed

    onValueChanged: {
        if (!initialized) {
            initialized = true;
            return;
        }
        if (Math.abs(value - oldValue) < 0.01)
            return;
        oldValue = value;
        handle.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: 500
        onTriggered: {
            if (!root.pressed)
                handle.moving = false;
        }
    }

    Behavior on value {
        Anim {
            type: Anim.StandardLarge
        }
    }
}
