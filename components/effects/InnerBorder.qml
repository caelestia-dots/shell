pragma ComponentBehavior: Bound

import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Effects

StyledRect {
    property alias innerRadius: maskInner.radius
    property alias thickness: maskInner.anchors.margins
    property alias leftThickness: maskInner.anchors.leftMargin
    property alias topThickness: maskInner.anchors.topMargin
    property alias rightThickness: maskInner.anchors.rightMargin
    property alias bottomThickness: maskInner.anchors.bottomMargin

    anchors.fill: parent
    color: Colours.tPalette.m3surfaceContainer

    layer.enabled: true
    layer.effect: MultiEffect {
        maskSource: mask
        maskEnabled: true
        maskInverted: true
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: maskInner

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            radius: Appearance.rounding.small
        }
    }
}
