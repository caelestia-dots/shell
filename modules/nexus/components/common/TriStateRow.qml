pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property string label
    property string value: ""

    signal triStateValueChanged(string newValue)

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    Behavior on implicitHeight {
        Anim {}
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: root.label
        }

        Item {
            id: toggle

            property bool hovered: mouseArea.containsMouse
            property bool pressed: mouseArea.pressed
            property int toggleState: root.value === "enable" ? 2 : root.value === "" ? 1 : 0

            implicitWidth: implicitHeight * 2.2
            implicitHeight: Tokens.font.size.normal + Tokens.padding.smaller * 2

            Rectangle {
                id: track

                anchors.fill: parent
                radius: height / 2
                color: toggle.toggleState === 2 ? Colours.palette.m3primary : toggle.toggleState === 0 ? Colours.palette.m3error : Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)

                Behavior on color {
                    CAnim {}
                }

                Rectangle {
                    id: thumb

                    readonly property real nonAnimWidth: toggle.pressed ? height * 1.3 : height
                    readonly property real thumbPadding: Tokens.padding.small / 2
                    readonly property real availableWidth: parent.width - thumbPadding * 2 - height
                    readonly property real leftPos: thumbPadding
                    readonly property real centerPos: thumbPadding + availableWidth / 2
                    readonly property real rightPos: thumbPadding + availableWidth

                    radius: height / 2
                    color: toggle.toggleState === 2 ? Colours.palette.m3onPrimary : toggle.toggleState === 0 ? Colours.palette.m3onError : Colours.layer(Colours.palette.m3outline, 2)

                    x: toggle.toggleState === 2 ? rightPos : toggle.toggleState === 1 ? centerPos : leftPos
                    width: nonAnimWidth
                    height: parent.height - Tokens.padding.small
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on x {
                        Anim {}
                    }

                    Behavior on width {
                        Anim {}
                    }

                    Behavior on color {
                        CAnim {}
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: toggle.toggleState === 2 ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        opacity: toggle.pressed ? 0.1 : toggle.hovered ? 0.08 : 0

                        Behavior on opacity {
                            Anim {}
                        }
                    }

                    Shape {
                        id: icon

                        property point start1: {
                            if (toggle.pressed)
                                return Qt.point(width * 0.2, height / 2);
                            if (toggle.toggleState === 2)
                                return Qt.point(width * 0.85, height / 2);
                            if (toggle.toggleState === 1)
                                return Qt.point(width * 0.2, height / 2);
                            return Qt.point(width * 0.15, height * 0.15);
                        }
                        property point end1: {
                            if (toggle.pressed) {
                                if (toggle.toggleState === 2)
                                    return Qt.point(width * 0.4, height / 2);
                                return Qt.point(width * 0.8, height / 2);
                            }
                            if (toggle.toggleState === 2)
                                return Qt.point(width * 0.6, height * 0.3);
                            if (toggle.toggleState === 1)
                                return Qt.point(width * 0.8, height / 2);
                            return Qt.point(width * 0.85, height * 0.85);
                        }
                        property point start2: {
                            if (toggle.pressed) {
                                if (toggle.toggleState === 2)
                                    return Qt.point(width * 0.4, height / 2);
                                return Qt.point(width * 0.2, height / 2);
                            }
                            if (toggle.toggleState === 2)
                                return Qt.point(width * 0.6, height * 0.3);
                            if (toggle.toggleState === 1)
                                return Qt.point(width * 0.2, height / 2);
                            return Qt.point(width * 0.15, height * 0.85);
                        }
                        property point end2: {
                            if (toggle.pressed)
                                return Qt.point(width * 0.8, height / 2);
                            if (toggle.toggleState === 2)
                                return Qt.point(width * 0.15, height * 0.8);
                            if (toggle.toggleState === 1)
                                return Qt.point(width * 0.2, height / 2);
                            return Qt.point(width * 0.85, height * 0.15);
                        }

                        anchors.centerIn: parent
                        width: height
                        height: parent.implicitHeight - Tokens.padding.small * 2
                        preferredRendererType: Shape.CurveRenderer
                        asynchronous: true

                        ShapePath {
                            strokeWidth: 3  // ~Tokens.font.size.larger * 0.15
                            strokeColor: toggle.toggleState === 2 ? Colours.palette.m3primary : toggle.toggleState === 0 ? Colours.palette.m3error : Colours.palette.m3surfaceContainerHighest
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap

                            startX: icon.start1.x
                            startY: icon.start1.y

                            PathLine {
                                x: icon.end1.x
                                y: icon.end1.y
                            }
                            PathMove {
                                x: icon.start2.x
                                y: icon.start2.y
                            }
                            PathLine {
                                x: icon.end2.x
                                y: icon.end2.y
                            }

                            Behavior on strokeColor {
                                CAnim {}
                            }
                        }

                        Behavior on start1 {
                            Anim {}
                        }
                        Behavior on end1 {
                            Anim {}
                        }
                        Behavior on start2 {
                            Anim {}
                        }
                        Behavior on end2 {
                            Anim {}
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.value === "")
                        root.triStateValueChanged("enable");
                    else if (root.value === "enable")
                        root.triStateValueChanged("disable");
                    else
                        root.triStateValueChanged("");
                }
            }
        }
    }
}
