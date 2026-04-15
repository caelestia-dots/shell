pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

Text {
    id: root

    property bool animate: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: Tokens.anim.durations.normal

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Colours.palette.m3onSurface
    font.family: Tokens.font.family.sans
    font.pointSize: Tokens.font.size.smaller

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                to: root.animateFrom
                easing: Tokens.anim.standardAccel
            }
            PropertyAction {}
            Anim {
                to: root.animateTo
                easing: Tokens.anim.standardDecel
            }
        }
    }

    component Anim: NumberAnimation {
        target: root
        property: root.animateProp
        duration: root.animateDuration / 2
    }
}
