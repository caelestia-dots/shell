pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property HyprlandMonitor monitor
    required property ShellScreen screen
    required property bool horizontal

    readonly property int activeSpecialId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0
    readonly property var wsIds: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.id);
    }
    readonly property int activeIdx: wsIds.indexOf(activeSpecialId)
    readonly property real maxViewY: Math.max(0, view.contentHeight - height)
    readonly property real maxViewX: Math.max(0, view.contentWidth - width)

    readonly property Workspace activeWs: {
        view.itemsDirty;
        return view.itemAtIndex(activeIdx) as Workspace;
    }

    function ensureVisible(animate = true): void {
        if (!activeWs)
            return;

        const start = horizontal ? activeWs.LazyListView.layoutX : activeWs.LazyListView.layoutY;
        const size = horizontal ? activeWs.LazyListView.preferredWidth : activeWs.LazyListView.preferredHeight;
        const viewLen = horizontal ? width : height;
        const maxScroll = horizontal ? maxViewX : maxViewY;

        let target = horizontal ? view.x : view.y;
        if (start < -target)
            target = -start;
        else if (start + size > -target + viewLen)
            target = -(start + size - viewLen);

        target = CUtils.clamp(target, -maxScroll, 0);
        if (target === (horizontal ? view.x : view.y))
            return;

        if (animate) {
            const anim = horizontal ? viewXAnim : viewYAnim;
            const type = anim.type;
            anim.type = Anim.DefaultSpatial;
            if (horizontal)
                view.x = target;
            else
                view.y = target;
            anim.type = type;
        } else {
            const bh = horizontal ? viewXBehavior : viewYBehavior;
            bh.enabled = false;
            if (horizontal)
                view.x = target;
            else
                view.y = target;
            bh.enabled = true;
        }
    }

    onActiveWsChanged: ensureVisible()
    onHeightChanged: ensureVisible(false)
    onWidthChanged: ensureVisible(false)
    Component.onCompleted: ensureVisible(false)
    onMaxViewYChanged: ensureVisible()
    onMaxViewXChanged: ensureVisible()

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Connections {
        function onLayoutXChanged(): void {
            root.ensureVisible();
        }

        function onLayoutYChanged(): void {
            root.ensureVisible();
        }

        function onPreferredWidthChanged(): void {
            root.ensureVisible();
        }

        function onPreferredHeightChanged(): void {
            root.ensureVisible();
        }

        target: root.activeWs?.LazyListView ?? null
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.8
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            radius: Tokens.rounding.full
            x: 0
            y: 0
            width: root.horizontal ? parent.width / 2 : parent.width
            height: root.horizontal ? parent.height : parent.height / 2
            opacity: root.horizontal ? (view.x < -Tokens.padding.extraSmall ? 0 : 1) : (view.y < -Tokens.padding.extraSmall ? 0 : 1)

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            radius: Tokens.rounding.full
            x: root.horizontal ? parent.width / 2 : 0
            y: root.horizontal ? 0 : parent.height / 2
            width: root.horizontal ? parent.width / 2 : parent.width
            height: root.horizontal ? parent.height : parent.height / 2
            opacity: root.horizontal ? (view.x > -root.maxViewX + Tokens.padding.extraSmall ? 0 : 1) : (view.y > -root.maxViewY + Tokens.padding.extraSmall ? 0 : 1)

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    LazyListView {
        id: view

        width: root.horizontal ? contentWidth : parent.width
        height: root.horizontal ? parent.height : contentHeight
        orientation: root.horizontal ? LazyListView.Horizontal : LazyListView.Vertical

        cullDelegates: false
        spacing: Tokens.spacing.small
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        onContentHeightChanged: root.ensureVisible()
        onContentWidthChanged: root.ensureVisible()

        model: ScriptModel {
            values: root.wsIds
        }

        delegate: Workspace {
            activeWsId: root.activeSpecialId
            ws: modelData
            monitor: root.monitor
            offMonitorColour: Colours.palette.m3outline
            horizontal: root.horizontal
            displayType: Config.bar.workspaces.specialDisplayType
            showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
        }

        Behavior on y {
            id: viewYBehavior
            enabled: !root.horizontal
            Anim {
                id: viewYAnim

                type: Anim.FastEffects
            }
        }

        Behavior on x {
            id: viewXBehavior
            enabled: root.horizontal
            Anim {
                id: viewXAnim

                type: Anim.FastEffects
            }
        }
    }

    Loader {
        asynchronous: true
        x: view.x
        y: view.y
        active: Config.bar.workspaces.activeIndicator

        sourceComponent: ActiveIndicator {
            horizontal: root.horizontal
            activeWs: root.activeWs
            mask: view
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
        }
    }

    MouseArea {
        property real startX
        property real startViewX
        property real startY
        property real startViewY
        property bool dragging

        anchors.fill: parent

        onPressed: event => {
            startX = event.x;
            startViewX = view.x;
            startY = event.y;
            startViewY = view.y;
            dragging = false;
        }

        onPositionChanged: event => {
            if (!dragging && Math.abs((root.horizontal ? event.x - startX : event.y - startY)) > drag.threshold)
                dragging = true;

            if (dragging && root.horizontal)
                view.x = CUtils.clamp(startViewX + (event.x - startX), -root.maxViewX, 0);
            else if (dragging)
                view.y = CUtils.clamp(startViewY + (event.y - startY), -root.maxViewY, 0);
        }

        onClicked: event => {
            if (dragging)
                return;

            const ws = view.itemAt(event.x - view.x, event.y - view.y) as Workspace;
            if (ws) {
                const match = Hypr.workspaces.values.find(w => w.id === ws.ws);
                if (match)
                    Hypr.toggleSpecial(Hypr.trimWsName(match.name));
            } else {
                Hypr.toggleSpecial("special");
            }
        }
    }
}
