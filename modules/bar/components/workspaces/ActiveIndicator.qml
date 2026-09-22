pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property Workspace activeWs
    required property Item mask
    property alias contentColour: colouriser.colorizationColor

    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"

    property real start
    property real end

    function runAnim(): void {
        if (!activeWs)
            return;

        const newStart = isHorizontal ? activeWs.x : activeWs.y;
        const newSize = isHorizontal ? activeWs.width : activeWs.height;

        const goingUp = newStart < start;
        
        const leadingDuration = 200;
        const trailingDuration = Config.bar.workspaces.activeTrail ? 250 : 200;

        startAnim.stop();
        endAnim.stop();
        startAnim.to = newStart;
        endAnim.to = newStart + newSize;
        startAnim.duration = goingUp ? leadingDuration : trailingDuration;
        endAnim.duration = goingUp ? trailingDuration : leadingDuration;
        startAnim.start();
        endAnim.start();
    }

    onActiveWsChanged: runAnim()
    Component.onCompleted: runAnim()

    clip: true

    x: isHorizontal ? start + mask.x : 0
    y: isHorizontal ? 0 : start + mask.y
    implicitWidth: isHorizontal ? end - start : mask.width
    implicitHeight: isHorizontal ? mask.height : end - start

    radius: Math.min(width, height) / 2
    color: Colours.palette.m3primary

    NumberAnimation on start {
        id: startAnim
        easing.type: Easing.OutCubic
    }

    NumberAnimation on end {
        id: endAnim
        easing.type: Easing.OutCubic
    }

    Connections {
        function onYChanged(): void {
            if (!root.isHorizontal)
                root.runAnim();
        }

        function onHeightChanged(): void {
            if (!root.isHorizontal)
                root.runAnim();
        }

        target: root.activeWs ?? null
    }

    Connections {
        function onXChanged(): void {
            if (root.isHorizontal)
                root.runAnim();
        }

        function onWidthChanged(): void {
            if (root.isHorizontal)
                root.runAnim();
        }

        target: root.activeWs ?? null
    }

    Colouriser {
        id: colouriser

        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: root.isHorizontal ? -parent.start : 0
        y: root.isHorizontal ? 0 : -parent.start
        implicitWidth: root.mask.width
        implicitHeight: root.mask.height

        anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
    }
}