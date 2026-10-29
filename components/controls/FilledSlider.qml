import "../effects"
import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

Slider {
    id: root

    required property string icon
    property real oldValue
    property bool initialized
    property bool handleTapEnabled: false
    property string transitionIcon: ""
    readonly property bool thumbDragging: thumbInput.dragging
    readonly property real displayedValue: thumbDragging ? thumbInput.previewValue : value
    property string lastIcon: ""
    property string displayedIcon: ""

    signal handleTapped
    signal handlePressed
    signal handleDragged(real nextValue)

    function updateIcon(): void {
        const previous = lastIcon;
        lastIcon = root.icon;
        if (!handleTapEnabled || !transitionIcon || handle.moving || !previous || (previous !== transitionIcon && root.icon !== transitionIcon)) {
            iconSwap.stop();
            iconVisual.scale = 1;
            displayedIcon = root.icon;
            return;
        }
        iconSwap.restart();
    }

    Component.onCompleted: {
        displayedIcon = root.icon;
        lastIcon = root.icon;
    }

    onIconChanged: root.updateIcon()

    orientation: Qt.Vertical

    background: StyledRect {
        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

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

        y: (root.thumbDragging && root.to !== root.from ? 1 - (root.displayedValue - root.from) / (root.to - root.from) : root.visualPosition) * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        Elevation {
            anchors.fill: parent
            radius: rect.radius
            level: (root.handleTapEnabled && thumbInput.containsMouse) || handleInteraction.containsMouse ? 2 : 1
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

            Item {
                id: iconVisual

                anchors.fill: parent
                transformOrigin: Item.Center

                MaterialIcon {
                    id: icon

                    property bool moving: false

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: moving ? Math.round(root.displayedValue * 100) : root.displayedIcon
                    color: Colours.palette.m3inverseOnSurface
                    font: moving ? Tokens.font.body.small : Tokens.font.icon.medium

                    onMovingChanged: {
                        if (root.handleTapEnabled && moving) {
                            iconSwap.stop();
                            iconVisual.scale = 1;
                            root.displayedIcon = root.icon;
                        }
                    }

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

            SequentialAnimation {
                id: iconSwap

                Anim {
                    target: iconVisual
                    property: "scale"
                    to: 0.65
                    duration: Tokens.anim.durations.small / 2
                    easing: Tokens.anim.standardAccel
                }
                ScriptAction {
                    script: root.displayedIcon = root.icon
                }
                Anim {
                    target: iconVisual
                    property: "scale"
                    to: 1
                    duration: Tokens.anim.durations.normal / 2
                    easing: Tokens.anim.standardDecel
                }
            }

            ThumbInputArea {
                id: thumbInput

                anchors.fill: parent
                enabled: root.handleTapEnabled
                slider: root

                onInteractionStarted: {
                    stateChangeDelay.stop();
                    handle.moving = false;
                    root.handlePressed();
                }
                onTapped: {
                    stateChangeDelay.stop();
                    handle.moving = false;
                    root.handleTapped();
                }
                onDragStarted: {
                    handle.moving = true;
                    stateChangeDelay.stop();
                }
                onDragMoved: nextValue => root.handleDragged(nextValue)
                onDragEnded: {
                    handle.moving = true;
                    stateChangeDelay.restart();
                }
            }
        }
    }

    onPressedChanged: {
        if (!root.handleTapEnabled) {
            handle.moving = pressed;
        } else if (pressed) {
            stateChangeDelay.stop();
            handle.moving = false;
        } else if (handle.moving) {
            stateChangeDelay.restart();
        }
    }

    onValueChanged: {
        if (thumbDragging) {
            oldValue = value;
            return;
        }

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
        enabled: !root.handleTapEnabled || (!root.pressed && !root.thumbDragging)

        Anim {
            type: Anim.StandardLarge
        }
    }
}
