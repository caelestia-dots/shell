import ".."
import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

StyledRect {
    id: root

    required property string label
    property string value: ""
    signal triStateValueChanged(string newValue)

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Appearance.padding.large * 2
    radius: Appearance.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    Behavior on implicitHeight {
        Anim {}
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: root.label
        }

        Item {
            id: toggle
            
            property bool hovered: mouseArea.containsMouse
            property bool pressed: mouseArea.pressed
            property int state: root.value === "enable" ? 2 : root.value === "" ? 1 : 0

            implicitWidth: implicitHeight * 2.2
            implicitHeight: Appearance.font.size.normal + Appearance.padding.smaller * 2

            Rectangle {
                id: track
                anchors.fill: parent
                radius: height / 2
                color: toggle.state === 2 ? Colours.palette.m3primary : 
                       toggle.state === 0 ? Colours.palette.m3error : 
                       Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }

                Rectangle {
                    id: thumb
                    readonly property real nonAnimWidth: toggle.pressed ? height * 1.3 : height
                    readonly property real thumbPadding: Appearance.padding.small / 2
                    readonly property real availableWidth: parent.width - (thumbPadding * 2) - height
                    readonly property real leftPos: thumbPadding
                    readonly property real centerPos: thumbPadding + (availableWidth / 2)
                    readonly property real rightPos: thumbPadding + availableWidth

                    radius: height / 2
                    color: toggle.state === 2 ? Colours.palette.m3onPrimary : 
                           toggle.state === 0 ? Colours.palette.m3onError : 
                           Colours.layer(Colours.palette.m3outline, 2)

                    x: toggle.state === 2 ? rightPos : toggle.state === 1 ? centerPos : leftPos
                    width: nonAnimWidth
                    height: parent.height - Appearance.padding.small
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on x {
                        NumberAnimation {
                            duration: Appearance.anim.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.standard
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Appearance.anim.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.standard
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.anim.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.standard
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: toggle.state === 2 ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        opacity: toggle.pressed ? 0.1 : toggle.hovered ? 0.08 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.anim.durations.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.anim.curves.standard
                            }
                        }
                    }

                    Shape {
                        id: icon

                        property point start1: {
                            if (toggle.pressed)
                                return Qt.point(width * 0.2, height / 2);
                            if (toggle.state === 2)
                                return Qt.point(width * 0.85, height / 2);
                            if (toggle.state === 1)
                                return Qt.point(width * 0.2, height / 2);
                            return Qt.point(width * 0.15, height * 0.15);
                        }
                        property point end1: {
                            if (toggle.pressed) {
                                if (toggle.state === 2)
                                    return Qt.point(width * 0.4, height / 2);
                                return Qt.point(width * 0.8, height / 2);
                            }
                            if (toggle.state === 2)
                                return Qt.point(width * 0.6, height * 0.3);
                            if (toggle.state === 1)
                                return Qt.point(width * 0.8, height / 2);
                            return Qt.point(width * 0.85, height * 0.85);
                        }
                        property point start2: {
                            if (toggle.pressed) {
                                if (toggle.state === 2)
                                    return Qt.point(width * 0.4, height / 2);
                                return Qt.point(width * 0.2, height / 2);
                            }
                            if (toggle.state === 2)
                                return Qt.point(width * 0.6, height * 0.3);
                            if (toggle.state === 1)
                                return Qt.point(width * 0.2, height / 2);
                            return Qt.point(width * 0.15, height * 0.85);
                        }
                        property point end2: {
                            if (toggle.pressed)
                                return Qt.point(width * 0.8, height / 2);
                            if (toggle.state === 2)
                                return Qt.point(width * 0.15, height * 0.8);
                            if (toggle.state === 1)
                                return Qt.point(width * 0.2, height / 2);
                            return Qt.point(width * 0.85, height * 0.15);
                        }

                        anchors.centerIn: parent
                        width: height
                        height: parent.implicitHeight - Appearance.padding.small * 2
                        preferredRendererType: Shape.CurveRenderer
                        asynchronous: true

                        ShapePath {
                            strokeWidth: Appearance.font.size.larger * 0.15
                            strokeColor: toggle.state === 2 ? Colours.palette.m3primary : 
                                        toggle.state === 0 ? Colours.palette.m3error : 
                                        Colours.palette.m3surfaceContainerHighest
                            fillColor: "transparent"
                            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

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
                            PropertyAnimation {
                                duration: Appearance.anim.durations.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.anim.curves.standard
                            }
                        }
                        Behavior on end1 {
                            PropertyAnimation {
                                duration: Appearance.anim.durations.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.anim.curves.standard
                            }
                        }
                        Behavior on start2 {
                            PropertyAnimation {
                                duration: Appearance.anim.durations.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.anim.curves.standard
                            }
                        }
                        Behavior on end2 {
                            PropertyAnimation {
                                duration: Appearance.anim.durations.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.anim.curves.standard
                            }
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
                    if (root.value === "") {
                        root.triStateValueChanged("enable");
                    } else if (root.value === "enable") {
                        root.triStateValueChanged("disable");
                    } else {
                        root.triStateValueChanged("");
                    }
                }
            }
        }
    }
}
