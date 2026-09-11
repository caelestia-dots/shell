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

    property int currentWsId: -1
    readonly property int currentWsIdx: currentWsId < 0 ? -1 : workspaceIndex(currentWsId)

    property real leading: workspaceOffset(currentWsIdx)
    property real trailing: workspaceOffset(currentWsIdx)
    property real currentSize: (workspaces.itemAt(currentWsIdx) as Workspace)?.size ?? 0
    property real offset: Math.min(leading, trailing)
    property real size: {
        const naturalSize = Math.abs(leading - trailing) + currentSize;
        if (Config.bar.workspaces.activeTrail && clampTrailEnd) {
            const clampedSize = Math.min(trailEnd - offset, naturalSize);
            return Math.max(currentSize, clampedSize);
        }
        return naturalSize;
    }
    property real trailEnd: 0
    property bool clampTrailEnd: false

    property bool ready: false
    property bool workspaceSwitchRunning: false
    readonly property bool switchAnimating: leadingAnim.running || trailingAnim.running || currentSizeAnim.running || offsetAnim.running || sizeAnim.running
    readonly property bool switchSettled: !switchAnimating && !layoutTransitionRunning
    readonly property bool geometryAnimationEnabled: ready && (!layoutTransitionRunning || workspaceSwitchRunning)

    function workspaceIndex(id: int): int {
        let index = id - 1;

        while (index < 0)
            index += Config.bar.workspaces.shown;

        return index % Config.bar.workspaces.shown;
    }

    function workspaceOffset(index: int): real {
        if (index < 0 || index >= workspaces.count)
            return 0;

        const ws = workspaces.itemAt(index) as Workspace;
        return ws ? (workspaceSwitchRunning ? ws.targetY : ws.y) : 0;
    }

    function updateCurrentWorkspace(withAnimation: bool): void {
        if (activeWsId === currentWsId)
            return;

        const nextIndex = workspaceIndex(activeWsId);
        const nextWorkspace = workspaces.itemAt(nextIndex) as Workspace;

        const previousOffset = offset;
        const previousEnd = previousOffset + size;

        if (withAnimation) {
            trailEnd = previousEnd;
            clampTrailEnd = Config.bar.workspaces.activeTrail && !!nextWorkspace && nextWorkspace.targetY < previousOffset;
            workspaceSwitchRunning = true;
        } else {
            endWorkspaceSwitch();
        }

        currentWsId = activeWsId;

        if (withAnimation)
            Qt.callLater(() => {
                if (switchSettled)
                    endWorkspaceSwitch();
            });
    }

    function endWorkspaceSwitch(): void {
        workspaceSwitchRunning = false;
        clampTrailEnd = false;
    }

    onActiveWsIdChanged: {
        if (ready)
            updateCurrentWorkspace(true);
    }

    onSwitchSettledChanged: {
        if (switchSettled)
            endWorkspaceSwitch();
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

        EAnim {
            id: leadingAnim
        }
    }

    Behavior on trailing {
        enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {
            id: trailingAnim

            duration: Tokens.anim.durations.normal * 2
        }
    }

    Behavior on currentSize {
        enabled: root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {
            id: currentSizeAnim
        }
    }

    Behavior on offset {
        enabled: !root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {
            id: offsetAnim
        }
    }

    Behavior on size {
        enabled: !root.Config.bar.workspaces.activeTrail && root.geometryAnimationEnabled

        EAnim {
            id: sizeAnim
        }
    }

    component EAnim: Anim {
        type: Anim.Emphasized
    }
}
