pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property int activeWsId
    required property Repeater workspaces
    required property Item mask
    required property bool fullscreen
    required property bool layoutTransitionRunning

    property int currentWsIdx: -1
    property int lastWs: -1

    property real leading: workspaceOffset(currentWsIdx)
    property real trailing: workspaceOffset(currentWsIdx)
    property real currentSize: (workspaces.itemAt(currentWsIdx) as Workspace)?.size ?? 0
    property real offset: Math.min(leading, trailing)
    property real size: {
        const s = Math.abs(leading - trailing) + currentSize;
        if (Config.bar.workspaces.activeTrail && lastWs > currentWsIdx) {
            const ws = workspaces.itemAt(lastWs) as Workspace;
            return ws ? Math.min(workspaceOffset(lastWs) + ws.size - offset, s) : 0;
        }
        return s;
    }

    property bool ready: false
    property bool workspaceSwitchRunning: false
    readonly property bool geometryAnimationEnabled: ready && (!layoutTransitionRunning || workspaceSwitchRunning)

    function workspaceIndex(id: int): int {
        let index = id - 1;

        while (index < 0)
            index += Config.bar.workspaces.shown;

        return index % Config.bar.workspaces.shown;
    }

    function workspaceOffset(index: int): real {
        if (index < 0)
            return 0;

        const ws = workspaces.itemAt(index) as Workspace;
        return ws ? (workspaceSwitchRunning ? ws.targetY : ws.y) : 0;
    }

    function updateCurrentWorkspace(withAnimation: bool): void {
        const nextIndex = workspaceIndex(activeWsId);
        if (nextIndex === currentWsIdx)
            return;

        if (withAnimation) {
            workspaceSwitchRunning = true;
            lastWs = currentWsIdx;
        } else {
            lastWs = nextIndex;
        }

        currentWsIdx = nextIndex;

        if (withAnimation)
            workspaceSwitchTimer.restart();
    }

    onActiveWsIdChanged: {
        if (ready)
            updateCurrentWorkspace(true);
    }

    clip: true
    y: offset + mask.y
    implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
    implicitHeight: size
    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Component.onCompleted: {
        updateCurrentWorkspace(false);
        ready = true;
    }

    Colouriser {
        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: 0
        y: -parent.offset
        implicitWidth: root.mask.implicitWidth
        implicitHeight: root.mask.implicitHeight

        anchors.horizontalCenter: parent.horizontalCenter
    }

    Behavior on leading {
        enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {}
    }

    Behavior on trailing {
        enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {
            duration: Tokens.anim.durations.normal * 2
        }
    }

    Behavior on currentSize {
        enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {}
    }

    Behavior on offset {
        enabled: !root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {}
    }

    Behavior on size {
        enabled: !root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {}
    }

    Timer {
        id: workspaceSwitchTimer

        interval: root.Config.bar.workspaces.activeTrail ? Tokens.anim.durations.normal * 2 : Tokens.anim.durations.normal
        onTriggered: root.workspaceSwitchRunning = false
    }

    component EAnim: Anim {
        type: Anim.Emphasized
    }
}
