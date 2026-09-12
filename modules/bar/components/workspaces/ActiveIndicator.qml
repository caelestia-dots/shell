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
    required property LazyListView view
    required property Item mask
    required property var workspaceIndex

    // property int currentWsId: -1
    // readonly property int currentWsIdx: currentWsId < 0 ? -1 : workspaceIndex(currentWsId)
    // property int switchWsIdx: -1

    // property real leading: workspaceOffset(switchWsIdx < 0 ? currentWsIdx : switchWsIdx)
    // property real trailing: workspaceOffset(switchWsIdx < 0 ? currentWsIdx : switchWsIdx)
    // property real currentSize: {
    //     workspaces.count;
    //     return (workspaces.itemAt(currentWsIdx) as Workspace)?.size ?? 0;
    // }
    // property real offset: Math.min(leading, trailing)
    // property real size: {
    //     const naturalSize = Math.abs(leading - trailing) + currentSize;
    //     if (Config.bar.workspaces.activeTrail && clampTrailEnd) {
    //         const clampedSize = Math.min(trailEnd - offset, naturalSize);
    //         return Math.max(currentSize, clampedSize);
    //     }
    //     return naturalSize;
    // }
    // property int trailWsIdx: -1
    // readonly property real trailEnd: {
    //     workspaces.count;
    //     const ws = workspaces.itemAt(trailWsIdx) as Workspace;
    //     return ws ? ws.y + ws.height : 0;
    // }
    // property bool clampTrailEnd: false

    property real offset

    function runAnim(): void {
        offsetAnim.stop();
        heightAnim.stop();
        offsetAnim.to = activeWs.LazyListView.layoutY;
        heightAnim.to = activeWs.LazyListView.preferredHeight + (activeWs.hasWindows ? Tokens.padding.extraSmall : 0);
        offsetAnim.start();
        heightAnim.start();
    }

    onActiveWsChanged: runAnim()
    Component.onCompleted: runAnim()

    clip: true
    y: offset + mask.y
    implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Anim on offset {
        id: offsetAnim
    }

    Anim on implicitHeight {
        id: heightAnim
    }

    Connections {
        function onLayoutYChanged(): void {
            root.runAnim();
        }

        function onPreferredHeightChanged(): void {
            root.runAnim();
        }

        target: root.activeWs.LazyListView
    }
    // TODO: trails
    // TODO: add/remove/move for workspaces animation

    Colouriser {
        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: 0
        y: -parent.offset
        implicitWidth: root.mask.width
        implicitHeight: root.mask.implicitHeight

        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Behavior on leading {
    //     enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

    //     EAnim {
    //         id: leadingAnim
    //     }
    // }

    // Behavior on trailing {
    //     enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

    //     EAnim {
    //         id: trailingAnim

    //         duration: Tokens.anim.durations.normal * 2
    //     }
    // }

    // Behavior on currentSize {
    //     enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

    //     EAnim {
    //         id: currentSizeAnim
    //     }
    // }

    // Behavior on offset {
    //     enabled: !root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

    //     EAnim {
    //         id: offsetAnim
    //     }
    // }

    // Behavior on size {
    //     enabled: !root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

    //     EAnim {
    //         id: sizeAnim
    //     }
    // }

    // component EAnim: Anim {
    //     type: Anim.Emphasized
    // }
}
