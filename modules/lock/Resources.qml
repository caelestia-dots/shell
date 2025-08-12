import qs.components
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

GridLayout {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Appearance.padding.large

    rowSpacing: Appearance.spacing.large
    columnSpacing: Appearance.spacing.large
    rows: 2
    columns: 2

    Ref {
        service: SystemUsage
    }

    Resource {
        Layout.topMargin: Appearance.padding.large
        icon: "memory"
        value: SystemUsage.cpuPerc
        colour: Colours.palette.m3primary
    }

    Resource {
        Layout.topMargin: Appearance.padding.large
        icon: "thermostat"
        value: Math.min(1, SystemUsage.cpuTemp / 90)
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Appearance.padding.large
        icon: "memory_alt"
        value: SystemUsage.memPerc
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Appearance.padding.large
        icon: "hard_disk"
        value: SystemUsage.storagePerc
        colour: Colours.palette.m3tertiary
    }

    component Resource: StyledRect {
        id: res

        required property string icon
        required property real value
        required property color colour

        readonly property int thickness: width < 200 ? Appearance.padding.smaller : Appearance.padding.normal
        readonly property real arcRadius: (width - Appearance.padding.large * 3 - thickness) / 2
        readonly property real vValue: value || 1 / 360
        readonly property real gapAngle: ((Appearance.spacing.small + thickness) / (arcRadius || 1)) * (180 / Math.PI)

        Layout.fillWidth: true
        implicitHeight: width

        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        radius: Appearance.rounding.large

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
                strokeWidth: res.thickness
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    startAngle: -90 + 360 * res.vValue + res.gapAngle
                    sweepAngle: 360 * (1 - res.vValue) - res.gapAngle * 2
                    radiusX: res.arcRadius
                    radiusY: res.arcRadius
                    centerX: res.width / 2
                    centerY: res.width / 2
                }

                Behavior on strokeColor {
                    ColorAnimation {
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: res.colour
                strokeWidth: res.thickness
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    startAngle: -90
                    sweepAngle: 360 * res.vValue
                    radiusX: res.arcRadius
                    radiusY: res.arcRadius
                    centerX: res.width / 2
                    centerY: res.width / 2
                }

                Behavior on strokeColor {
                    ColorAnimation {
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: res.icon
            color: res.colour
            font.pointSize: (res.arcRadius * 0.7) || 1
            font.weight: 600
        }

        Behavior on value {
            NumberAnimation {
                duration: Appearance.anim.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    component Anim: ColorAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
