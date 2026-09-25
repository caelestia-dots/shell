pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property Workspace activeWs
    required property Item mask
    property bool isHorizontal: false
    property alias contentColour: colouriser.colorizationColor

    property real start
    property real end

    function runAnim(): void {
        if (!activeWs)
            return;

        const newStart = activeWs.layoutStart;
        const goingBack = newStart < start;
        const leadingDuration = Tokens.anim.durations.expressiveDefaultSpatial;
        const trailingDuration = leadingDuration * (Config.bar.workspaces.activeTrail ? 1.5 : 1);

        startAnim.stop();
        endAnim.stop();
        startAnim.to = newStart;
        endAnim.to = newStart + activeWs.layoutLength;
        startAnim.duration = goingBack ? leadingDuration : trailingDuration;
        endAnim.duration = goingBack ? trailingDuration : leadingDuration;
        startAnim.start();
        endAnim.start();
    }

    onActiveWsChanged: runAnim()
    Component.onCompleted: runAnim()

    clip: true
    x: root.isHorizontal ? (start + mask.x) : 0
    y: root.isHorizontal ? 0 : (start + mask.y)
    implicitWidth: root.isHorizontal ? Math.max(end - start, activeWs?.width ?? 0) : mask.width
    implicitHeight: root.isHorizontal ? mask.height : (end - start)
    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Anim on start {
        id: startAnim
    }

    Anim on end {
        id: endAnim
    }

    Connections {
        function onLayoutStartChanged(): void {
            root.runAnim();
        }

        function onLayoutLengthChanged(): void {
            root.runAnim();
        }

        target: root.activeWs
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
