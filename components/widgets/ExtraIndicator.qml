import "../effects"
import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    required property int extra

    anchors.right: parent.right
    anchors.margins: Tokens.padding.normal

    color: Colours.palette.m3tertiary
    radius: Tokens.rounding.small

    implicitWidth: count.implicitWidth + Tokens.padding.normal * 2
    implicitHeight: count.implicitHeight + Tokens.padding.small * 2

    opacity: extra > 0 ? 1 : 0
    scale: extra > 0 ? 1 : 0.5

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 2
    }

    StyledText {
        id: count

        anchors.centerIn: parent
        animate: parent.opacity > 0
        text: qsTr("+%1").arg(parent.extra)
        color: Colours.palette.m3onTertiary
    }

    Behavior on opacity {
        Anim {
            duration: Tokens.anim.durations.expressiveFastSpatial
        }
    }

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
