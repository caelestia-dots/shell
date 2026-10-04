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
    required property bool horizontal
    property alias contentColour: colouriser.colorizationColor

    property real start
    property real end

    function runAnim(): void {
        if (!activeWs)
            return;

        const newStart = horizontal ? activeWs.LazyListView.layoutX : activeWs.LazyListView.layoutY;
        const goingForwards = newStart > start;
        const leadingDuration = Tokens.anim.durations.expressiveDefaultSpatial;
        const trailingDuration = leadingDuration * (Config.bar.workspaces.activeTrail ? 1.5 : 1);

        startAnim.stop();
        endAnim.stop();
        startAnim.to = newStart;
        endAnim.to = newStart + (horizontal ? activeWs.LazyListView.preferredWidth : activeWs.LazyListView.preferredHeight);
        startAnim.duration = goingForwards ? leadingDuration : trailingDuration;
        endAnim.duration = goingForwards ? trailingDuration : leadingDuration;
        startAnim.start();
        endAnim.start();
    }

    onActiveWsChanged: runAnim()
    Component.onCompleted: runAnim()

    clip: true
    x: horizontal ? start + mask.x : 0
    y: horizontal ? 0 : start + mask.y
    width: horizontal ? end - start : mask.width
    height: horizontal ? mask.height : end - start
    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Anim on start {
        id: startAnim
    }

    Anim on end {
        id: endAnim
    }

    Connections {
        function onLayoutXChanged(): void {
            root.runAnim();
        }

        function onLayoutYChanged(): void {
            root.runAnim();
        }

        function onPreferredWidthChanged(): void {
            root.runAnim();
        }

        function onPreferredHeightChanged(): void {
            root.runAnim();
        }

        target: root.activeWs?.LazyListView ?? null
    }

    Colouriser {
        id: colouriser

        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: root.horizontal ? -parent.start : 0
        y: root.horizontal ? 0 : -parent.start
        implicitWidth: root.mask.width
        implicitHeight: root.mask.height
    }
}
