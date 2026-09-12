// qmllint disable unqualified
// qmllint disable Quick.property-changes-parsed

import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    id: passwordField

    property bool canSubmit: false
    property var submit: function () {}

    onTextChanged: submitReveal.restart()

    focus: true
    selectByMouse: true
    cursorVisible: false
    echoMode: config.HidePassword === "true" ? TextInput.Password : TextInput.Normal
    passwordCharacter: "•"
    leftPadding: 48 * config.Scale
    rightPadding: 52 * config.Scale

    font {
        family: config.FontFamily
        pointSize: config.FontSize
        bold: true
    }

    placeholderText: config.PassPlaceholderText
    horizontalAlignment: TextInput.AlignHCenter

    // Caelestia renders animated shapes for passphrase characters instead of dots.
    color: "transparent"
    selectedTextColor: "transparent"
    selectionColor: "transparent"
    placeholderTextColor: config.DateColor
    renderType: Text.NativeRendering

    states: [
        State {
            name: "focused"
            when: passwordField.activeFocus

            PropertyChanges {
                target: passFieldBg
                color: Qt.darker(config.InputColor, 1.2)
                border.width: config.InputBorderWidth
            }
        },
        State {
            name: "hovered"
            when: passwordField.hovered

            PropertyChanges {
                target: passFieldBg
                color: Qt.darker(config.InputColor, 1.2)
            }
        }
    ]

    background: Rectangle {
        id: passFieldBg

        border {
            color: config.InputBorderColor
            width: 0
        }

        color: config.InputColor

        radius: height / 2

        Text {
            anchors {
                left: parent.left
                leftMargin: 16 * config.Scale
                verticalCenter: parent.verticalCenter
            }
            text: "lock"
            color: config.DateColor
            font {
                family: "Material Symbols Rounded"
                pointSize: 20 * config.Scale
            }
            renderType: Text.NativeRendering
        }

        Rectangle {
            id: submitButton

            property real revealScale: 1
            anchors {
                right: parent.right
                rightMargin: 6 * config.Scale
                verticalCenter: parent.verticalCenter
            }

            width: passwordField.canSubmit ? 42 * config.Scale : 36 * config.Scale
            height: width
            radius: height / 2
            color: passwordField.canSubmit ? config.LoginButtonColor : config.ClockChipColor

            Behavior on width {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutBack
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 180
                }
            }

            scale: revealScale * (submitMouse.pressed ? 0.82 : submitMouse.containsMouse && passwordField.canSubmit ? 1.08 : 1)

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                anchors.centerIn: parent
                text: "arrow_forward"
                color: passwordField.canSubmit ? config.LoginButtonTextColor : config.DateColor
                font {
                    family: "Material Symbols Rounded"
                    pointSize: 20 * config.Scale
                }
                renderType: Text.NativeRendering
                opacity: passwordField.canSubmit ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: submitMouse

                anchors.fill: parent
                enabled: passwordField.canSubmit
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: passwordField.submit()
            }
        }
    }

    Item {
        id: passphraseViewport
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: passwordField.leftPadding
            rightMargin: passwordField.rightPadding
            verticalCenter: parent.verticalCenter
        }

        height: parent.height
        clip: true
        z: 2

        Row {
            id: passphraseShapes

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: implicitWidth > passphraseViewport.width ? -(implicitWidth - passphraseViewport.width) / 2 : 0
            spacing: 6 * config.Scale
            visible: passwordField.text.length > 0

            Repeater {
                model: passwordField.text.length

                delegate: Item {
                    id: shapeDelegate

                    property int shapeKind: index % 5
                    property real morph: 0

                    width: 17 * config.Scale
                    height: 26 * config.Scale
                    scale: 2 / 3
                    opacity: 0

                    Canvas {
                        property int currentShape: shapeDelegate.shapeKind
                        property real shapeMorph: shapeDelegate.morph

                        anchors.centerIn: parent
                        width: 16 * config.Scale
                        height: width
                        antialiasing: true

                        onPaint: {
                            const ctx = getContext("2d");
                            const side = width;
                            const half = side / 2;
                            const kind = currentShape;
                            const samples = 32;
                            const finalRadius = side * 0.48;
                            let sides = 0;
                            let rotation = 0;
                            let initialRadius = side * 0.48;

                            if (kind === 1) {
                                sides = 3;
                                rotation = -Math.PI / 2;
                                initialRadius = side * 0.42;
                            } else if (kind === 2) {
                                sides = 4;
                                rotation = 0;
                                initialRadius = side * 0.42;
                            } else if (kind === 3) {
                                sides = 5;
                                rotation = -Math.PI / 2;
                                initialRadius = side * 0.42;
                            } else if (kind === 4) {
                                sides = 6;
                                rotation = Math.PI / 6;
                                initialRadius = side * 0.41;
                            }

                            function polygonRadius(angle) {
                                if (sides === 0)
                                    return initialRadius;
                                const sector = Math.PI * 2 / sides;
                                const offset = ((angle - rotation + sector / 2) % sector + sector) % sector - sector / 2;
                                return initialRadius * Math.cos(Math.PI / sides) / Math.cos(offset);
                            }

                            ctx.clearRect(0, 0, side, side);
                            ctx.fillStyle = config.InputTextColor;
                            ctx.strokeStyle = config.InputTextColor;
                            ctx.lineJoin = "round";
                            ctx.lineWidth = Math.max(1, 1.2 * config.Scale);
                            ctx.beginPath();

                            for (let point = 0; point < samples; point++) {
                                const angle = -Math.PI / 2 + point * Math.PI * 2 / samples;
                                const radius = polygonRadius(angle) * (1 - shapeMorph) + finalRadius * shapeMorph;
                                const x = half + Math.cos(angle) * radius;
                                const y = half + Math.sin(angle) * radius;
                                if (point === 0)
                                    ctx.moveTo(x, y);
                                else
                                    ctx.lineTo(x, y);
                            }

                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();
                        }

                        onCurrentShapeChanged: requestPaint()
                        onShapeMorphChanged: requestPaint()
                    }

                    SequentialAnimation on scale {
                        running: true

                        NumberAnimation {
                            from: 0
                            to: 1
                            duration: 160
                            easing.type: Easing.OutBack
                        }

                        PauseAnimation {
                            duration: 180
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: shapeDelegate
                                property: "morph"
                                to: 1
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                to: 2 / 3
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    NumberAnimation on opacity {
                        running: true
                        from: 0
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: submitReveal

        NumberAnimation {
            target: submitButton
            property: "revealScale"
            to: 0.72
            duration: 70
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: submitButton
            property: "revealScale"
            to: 1.12
            duration: 160
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: submitButton
            property: "revealScale"
            to: 1
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    transitions: Transition {
        PropertyAnimation {
            properties: "color, border.width"
            duration: 150
        }
    }
}
