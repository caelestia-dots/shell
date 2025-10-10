import ".."
import "../effects"
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates

Slider {
    id: root

    required property string icon
    property real oldValue
    property bool initialized

    orientation: Qt.Vertical

    background: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right

            y: root.handle.y
            implicitHeight: parent.height - y

            color: Colours.palette.m3secondary
            radius: parent.radius
        }
    }

    handle: Item {
        id: handle

        property alias moving: icon.moving

        y: root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        Elevation {
            anchors.fill: parent
            radius: rect.radius
            level: handleInteraction.containsMouse ? 2 : 1
        }

        StyledRect {
            id: rect

            anchors.fill: parent

            color: Colours.palette.m3inverseSurface
            radius: Appearance.rounding.full

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

                function update(): void {
                    animate = !moving;
                    binding.when = moving;
                    font.pointSize = moving ? Appearance.font.size.small : Appearance.font.size.larger;
                    font.family = moving ? Appearance.font.family.sans : Appearance.font.family.material;
                }

                text: root.icon
                color: Colours.palette.m3inverseOnSurface
                anchors.centerIn: parent

                onMovingChanged: anim.restart()

                Binding {
                    id: binding

                    target: icon
                    property: "text"
                    value: Math.round(root.value * 100)
                    when: false
                }

                SequentialAnimation {
                    id: anim

                    Anim {
                        target: icon
                        property: "scale"
                        to: 0
                        duration: Appearance.anim.durations.normal / 2
                        easing.bezierCurve: Appearance.anim.curves.standardAccel
                    }
                    ScriptAction {
                        script: icon.update()
                    }
                    Anim {
                        target: icon
                        property: "scale"
                        to: 1
                        duration: Appearance.anim.durations.normal / 2
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
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
            duration: Appearance.anim.durations.large
        }
    }
}
