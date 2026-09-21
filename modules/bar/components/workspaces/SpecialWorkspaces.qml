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

    readonly property int activeSpecialId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0
    readonly property var wsIds: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.id);
    }
    readonly property int activeIdx: wsIds.indexOf(activeSpecialId)
    readonly property real maxViewY: Math.max(0, view.contentHeight - height)

    readonly property Workspace activeWs: {
        view.itemsDirty;
        return view.itemAtIndex(activeIdx) as Workspace;
    }

    function ensureVisible(animate = true): void {
        if (!activeWs)
            return;

        const top = activeWs.LazyListView.layoutY;
        const bottom = top + activeWs.LazyListView.preferredHeight;

        let target = view.y;
        if (top < -target)
            target = -top;
        else if (bottom > -target + height)
            target = -(bottom - height);

        target = CUtils.clamp(target, -maxViewY, 0);
        if (target !== view.y) {
            if (animate) {
                const type = viewYAnim.type;
                viewYAnim.type = Anim.DefaultSpatial;
                view.y = target;
                viewYAnim.type = type;
            } else {
                viewYBehavior.enabled = false;
                view.y = target;
                viewYBehavior.enabled = true;
            }
        }
    }

    onActiveWsChanged: ensureVisible()
    onHeightChanged: ensureVisible(false)
    Component.onCompleted: ensureVisible(false)
    onMaxViewYChanged: ensureVisible()

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Connections {
        function onLayoutYChanged(): void {
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
                orientation: Gradient.Vertical

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
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.y < -Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            radius: Tokens.rounding.full
            implicitHeight: parent.height / 2
            opacity: view.y > -root.maxViewY + Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    LazyListView {
        id: view

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: contentHeight

        cullDelegates: false
        spacing: Tokens.spacing.small
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        onContentHeightChanged: root.ensureVisible()

        model: ScriptModel {
            values: root.wsIds
        }

        delegate: Workspace {
            activeWsId: root.activeSpecialId
            ws: modelData
            monitor: root.monitor
            offMonitorColour: Colours.palette.m3outline
            displayType: Config.bar.workspaces.specialDisplayType
            showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
        }

        Behavior on y {
            id: viewYBehavior

            Anim {
                id: viewYAnim

                type: Anim.FastEffects
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.left: view.left
        anchors.right: view.right
        active: Config.bar.workspaces.activeIndicator

        sourceComponent: ActiveIndicator {
            activeWs: root.activeWs
            mask: view
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
        }
    }

    MouseArea {
        property real startY
        property real startViewY
        property bool dragging

        anchors.fill: parent

        onPressed: event => {
            startY = event.y;
            startViewY = view.y;
            dragging = false;
        }

        onPositionChanged: event => {
            if (!dragging && Math.abs(event.y - startY) > drag.threshold)
                dragging = true;

            if (dragging)
                view.y = CUtils.clamp(startViewY + (event.y - startY), -root.maxViewY, 0);
        }

        onClicked: event => {
            if (dragging)
                return;

            const ws = view.itemAt(event.x, event.y - view.y) as Workspace;
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
