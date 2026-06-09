pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.lock

Item {
    id: root

    required property Pam pam
    readonly property alias placeholder: placeholder
    property string buffer

    clip: true

    Connections {
        function onBufferChanged(): void {
            if (root.pam.buffer.length > root.buffer.length) {
                charList.bindImWidth();
            } else if (root.pam.buffer.length === 0) {
                charList.implicitWidth = charList.implicitWidth;
                placeholder.animate = true;
            }

            root.buffer = root.pam.buffer;
        }

        target: root.pam
    }

    StyledText {
        id: placeholder

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1

        text: {
            if (root.pam.passwd.active)
                return qsTr("Loading...");
            if (root.pam.state === "max")
                return qsTr("You have reached the maximum number of tries");
            return qsTr("Enter your password");
        }

        animate: true
        color: root.pam.passwd.active ? Colours.palette.m3secondary : Colours.palette.m3outline
        font: Tokens.font.body.builders.small.width(110).build()

        opacity: root.buffer ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ListView {
        id: charList

        readonly property int fullWidth: {
            let w = (count - 1) * spacing;
            for (let i = 0; i < count; i++)
                w += ((itemAtIndex(i) as CharItem)?.nonAnimWidthScale ?? 1) * implicitHeight;
            return w + implicitHeight; // Extra padding at ends
        }

        function bindImWidth(): void {
            imWidthBehavior.enabled = false;
            implicitWidth = Qt.binding(() => fullWidth);
            imWidthBehavior.enabled = true;
        }

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: implicitWidth > root.width ? -(implicitWidth - root.width) / 2 : 0

        implicitWidth: fullWidth
        implicitHeight: Tokens.font.body.medium.pointSize

        orientation: Qt.Horizontal
        spacing: Tokens.spacing.extraSmall
        interactive: false

        model: ScriptModel {
            values: root.buffer.split("")
        }

        delegate: CharItem {}

        Behavior on implicitWidth {
            id: imWidthBehavior

            Anim {}
        }
    }

    component CharItem: Item {
        id: char

        property real nonAnimWidthScale: 1

        implicitHeight: charList.implicitHeight

        ListView.onRemove: {
            initAnim.stop();
            removeAnim.start();
        }

        MaterialShape {
            id: charShape

            anchors.centerIn: parent
            implicitSize: charList.implicitHeight * 1.5
            shape: {
                const shapes = [MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Fan, MaterialShape.Arrow, MaterialShape.SemiCircle, MaterialShape.Triangle, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Sunny, MaterialShape.VerySunny, MaterialShape.Cookie4Sided, MaterialShape.Ghostish, MaterialShape.SoftBurst];
                return shapes[Math.floor(Math.random() * shapes.length)];
            }
            color: Colours.palette.m3onSurface

            Behavior on color {
                CAnim {}
            }

            SequentialAnimation {
                id: initAnim

                running: true

                ParallelAnimation {
                    Anim {
                        target: charShape
                        property: "opacity"
                        from: 0
                        to: 1
                        type: Anim.DefaultEffects
                    }
                    Anim {
                        target: charShape
                        property: "scale"
                        from: 0
                        to: 1
                        type: Anim.FastSpatial
                    }
                    Anim {
                        target: char
                        property: "implicitWidth"
                        from: charList.implicitHeight
                        to: charList.implicitHeight * 1.3
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1.5
                    }
                }
                PauseAnimation {
                    duration: 180 * Tokens.anim.durations.scale
                }
                PropertyAction {
                    target: charShape
                    property: "shape"
                    value: MaterialShape.Circle
                }
                ParallelAnimation {
                    Anim {
                        target: charShape
                        property: "scale"
                        to: 2 / 3
                        type: Anim.FastSpatial
                    }
                    Anim {
                        target: char
                        property: "implicitWidth"
                        to: charList.implicitHeight
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1
                    }
                }
            }

            SequentialAnimation {
                id: removeAnim

                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: true
                }
                ParallelAnimation {
                    Anim {
                        type: Anim.DefaultEffects
                        target: charShape
                        property: "opacity"
                        to: 0
                    }
                    Anim {
                        target: charShape
                        property: "scale"
                        to: 0.5
                    }
                }
                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: false
                }
            }
        }
    }
}
