import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    required property var currentItem

    implicitWidth: content.implicitWidth + Appearance.padding.larger + content.anchors.rightMargin
    implicitHeight: currentItem ? content.implicitHeight + Appearance.padding.normal + content.anchors.bottomMargin : 0

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: path

            readonly property real rounding: Appearance.rounding.small
            readonly property bool flatten: root.implicitHeight < rounding * 2
            readonly property real roundingY: flatten ? root.implicitHeight / 2 : rounding

            strokeWidth: -1
            fillColor: Colours.palette.m3surfaceContainer

            startX: root.implicitWidth
            startY: root.implicitHeight

            PathLine {
                relativeX: -(root.implicitWidth + path.rounding)
                relativeY: 0
            }
            PathArc {
                relativeX: path.rounding
                relativeY: -path.roundingY
                radiusX: path.rounding
                radiusY: Math.min(path.rounding, root.implicitHeight)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: 0
                relativeY: -(root.implicitHeight - path.roundingY * 2)
            }
            PathArc {
                relativeX: path.rounding
                relativeY: -path.roundingY
                radiusX: path.rounding
                radiusY: Math.min(path.rounding, root.implicitHeight)
            }
            PathLine {
                relativeX: root.implicitHeight > 0 ? root.implicitWidth - path.rounding * 2 : root.implicitWidth
                relativeY: 0
            }
            PathArc {
                relativeX: path.rounding
                relativeY: -path.rounding
                radiusX: path.rounding
                radiusY: path.rounding
                direction: PathArc.Counterclockwise
            }

            Behavior on fillColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        StyledText {
            id: content

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Appearance.padding.larger - Appearance.padding.small
            anchors.bottomMargin: Appearance.padding.normal - Appearance.padding.small

            text: qsTr(`"%1" selected`).arg(root.currentItem?.fileName)
        }
    }

    Behavior on implicitWidth {
        enabled: !!root.currentItem

        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
