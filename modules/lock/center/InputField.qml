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
        function onBufferChanged() {
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

        text: {
            if (root.pam.passwd.active)
                return qsTr("Loading...");
            if (root.pam.state === "max")
                return qsTr("You have reached the maximum number of tries");
            return qsTr("Enter your password");
        }

        animate: true
        color: root.pam.passwd.active ? Colours.palette.m3secondary : Colours.palette.m3outline
        font: Tokens.font.mono.medium

        opacity: root.buffer ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ListView {
        id: charList

        readonly property int fullWidth: count * (implicitHeight + spacing) - spacing

        function bindImWidth() {
            imWidthBehavior.enabled = false;
            implicitWidth = Qt.binding(() => fullWidth);
            imWidthBehavior.enabled = true;
        }

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: implicitWidth > root.width ? -(implicitWidth - root.width) / 2 : 0

        implicitWidth: fullWidth
        implicitHeight: Tokens.font.body.medium.pointSize

        orientation: Qt.Horizontal
        spacing: Tokens.spacing.small
        interactive: false

        model: ScriptModel {
            values: root.buffer.split("")
        }

        delegate: Item {
            id: delegateRoot

            implicitWidth: charList.implicitHeight
            implicitHeight: charList.implicitHeight

            ListView.onRemove: removeAnim.start()

            SequentialAnimation {
                id: removeAnim

                PropertyAction {
                    target: delegateRoot
                    property: "ListView.delayRemove"
                    value: true
                }
                ParallelAnimation {
                    Anim {
                        type: Anim.DefaultEffects
                        target: delegateRoot
                        property: "opacity"
                        to: 0
                    }
                    Anim {
                        target: ch
                        property: "implicitSize"
                        to: 0
                    }
                }
                PropertyAction {
                    target: delegateRoot
                    property: "ListView.delayRemove"
                    value: false
                }
            }

            MaterialShape {
                id: ch

                property int initialShape: {
                    const shapes = [MaterialShape.Square, MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Fan, MaterialShape.Arrow, MaterialShape.SemiCircle, MaterialShape.Triangle, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Sunny, MaterialShape.VerySunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Ghostish, MaterialShape.Clover4Leaf, MaterialShape.Clover8Leaf, MaterialShape.Burst, MaterialShape.SoftBurst, MaterialShape.Boom, MaterialShape.SoftBoom, MaterialShape.Flower, MaterialShape.Puffy, MaterialShape.PuffyDiamond, MaterialShape.Bun, MaterialShape.Heart];
                    return shapes[Math.floor(Math.random() * shapes.length)];
                }

                anchors.centerIn: parent

                color: Colours.palette.m3onSurface

                shape: initialShape
                animationDuration: 200

                opacity: 0
                implicitSize: 0

                Component.onCompleted: {
                    spawnAnim.start();
                }

                SequentialAnimation {
                    id: spawnAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: ch
                            property: "implicitSize"
                            from: 0
                            to: delegateRoot.implicitHeight * 1.5
                            duration: 250
                            easing.type: Easing.OutBack
                        }
                        NumberAnimation {
                            target: ch
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 100
                        }
                    }

                    PauseAnimation {
                        duration: 180
                    }

                    ScriptAction {
                        script: ch.shape = MaterialShape.Circle
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: ch
                            property: "implicitSize"
                            to: delegateRoot.implicitHeight
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        Behavior on implicitWidth {
            id: imWidthBehavior

            Anim {}
        }
    }
}
