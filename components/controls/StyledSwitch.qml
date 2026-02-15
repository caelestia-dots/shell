import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Templates
import QtQuick.Shapes

Switch {
    id: root

    property int cLayer: 1

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    indicator: StyledRect {
        radius: Appearance.rounding.full
        color: root.checked ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)

        implicitWidth: implicitHeight * 1.7
        implicitHeight: Appearance.font.size.normal + Appearance.padding.smaller * 2

        StyledRect {
            readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.3 : implicitHeight

            radius: Appearance.rounding.full
            color: root.checked ? Colours.palette.m3onPrimary : Colours.layer(Colours.palette.m3outline, root.cLayer + 1)

            x: root.checked ? parent.implicitWidth - nonAnimWidth - Appearance.padding.small / 2 : Appearance.padding.small / 2
            implicitWidth: nonAnimWidth
            implicitHeight: parent.implicitHeight - Appearance.padding.small
            anchors.verticalCenter: parent.verticalCenter

            StyledRect {
                anchors.fill: parent
                radius: parent.radius

                color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface
                opacity: root.pressed ? 0.1 : root.hovered ? 0.08 : 0

                Behavior on opacity {
                    Anim {}
                }
            }

            Shape {
                id: icon

                property point start1: {
                    if (root.pressed)
                        return Qt.point(width * 0.2, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.15, height / 2);
                    return Qt.point(width * 0.15, height * 0.15);
                }
                property point end1: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.8, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.85, height * 0.85);
                }
                property point start2: {
                    if (root.pressed) {
                        if (root.checked)
                            return Qt.point(width * 0.4, height / 2);
                        return Qt.point(width * 0.2, height / 2);
                    }
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.15, height * 0.85);
                }
                property point end2: {
                    if (root.pressed)
                        return Qt.point(width * 0.8, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.85, height * 0.2);
                    return Qt.point(width * 0.85, height * 0.15);
                }

                anchors.centerIn: parent
                width: height
                height: parent.implicitHeight - Appearance.padding.small * 2
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                ShapePath {
                    strokeWidth: Appearance.font.size.larger * 0.15
                    strokeColor: root.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest
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
                    PropAnim {}
                }
                Behavior on end1 {
                    PropAnim {}
                }
                Behavior on start2 {
                    PropAnim {}
                }
                Behavior on end2 {
                    PropAnim {}
                }
            }

            Behavior on x {
                Anim {}
            }

            Behavior on implicitWidth {
                Anim {}
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }

    component PropAnim: PropertyAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
