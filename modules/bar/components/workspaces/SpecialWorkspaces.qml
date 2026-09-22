pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property HyprlandMonitor monitor

    readonly property string edge: Config.bar.alignment
    readonly property bool isHorizontal: edge === "top" || edge === "bottom"

    readonly property int activeSpecialId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0
    readonly property var wsIds: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.id);
    }
    readonly property int activeIdx: wsIds.indexOf(activeSpecialId)
    readonly property real maxViewY: Math.max(0, view.contentHeight - height)
    readonly property real maxViewX: Math.max(0, view.contentWidth - width)

    property int itemsRev: 0

    readonly property Item activeWs: {
        root.itemsRev;
        if (activeIdx >= 0 && activeIdx < rep.count) {
            return view.itemAtIndex(activeIdx);
        }
        return null;
    }

    function ensureVisible(animate = true): void {
        if (!activeWs)
            return;

        const pos = root.isHorizontal ? activeWs.x : activeWs.y;
        const size = root.isHorizontal ? activeWs.width : activeWs.height;

        let target = root.isHorizontal ? view.x : view.y;
        const viewportSize = root.isHorizontal ? width : height;

        if (pos < -target)
            target = -pos;
        else if (pos + size > -target + viewportSize)
            target = -(pos + size - viewportSize);

        target = CUtils.clamp(target, -(root.isHorizontal ? maxViewX : maxViewY), 0);

        if (target !== (root.isHorizontal ? view.x : view.y)) {
            if (animate) {
                const anim = root.isHorizontal ? viewXAnim : viewYAnim;
                const type = anim.type;
                anim.type = Anim.DefaultSpatial;
                if (root.isHorizontal) view.x = target;
                else view.y = target;
                anim.type = type;
            } else {
                if (root.isHorizontal) {
                    viewXBehavior.enabled = false;
                    view.x = target;
                    viewXBehavior.enabled = true;
                } else {
                    viewYBehavior.enabled = false;
                    view.y = target;
                    viewYBehavior.enabled = true;
                }
            }
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

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: root.isHorizontal ? Gradient.Horizontal : Gradient.Vertical

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
            anchors.bottom: root.isHorizontal ? parent.bottom : undefined
            anchors.left: parent.left
            anchors.right: root.isHorizontal ? undefined : parent.right

            radius: Tokens.rounding.full
            implicitHeight: root.isHorizontal ? parent.height : parent.height / 2
            implicitWidth: root.isHorizontal ? parent.width / 2 : parent.width
            opacity: (root.isHorizontal ? view.x : view.y) < -Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.top: root.isHorizontal ? parent.top : undefined
            anchors.right: parent.right
            anchors.left: root.isHorizontal ? undefined : parent.left
            radius: Tokens.rounding.full
            implicitHeight: root.isHorizontal ? parent.height : parent.height / 2
            implicitWidth: root.isHorizontal ? parent.width / 2 : parent.width
            opacity: (root.isHorizontal ? view.x : view.y) > -(root.isHorizontal ? root.maxViewX : root.maxViewY) + Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    Item {
        id: view

        anchors.left: root.isHorizontal ? undefined : parent.left
        anchors.right: root.isHorizontal ? undefined : parent.right
        anchors.top: root.isHorizontal ? parent.top : undefined
        anchors.bottom: root.isHorizontal ? parent.bottom : undefined
        
        implicitHeight: root.isHorizontal ? parent.height : layout.implicitHeight
        implicitWidth: root.isHorizontal ? layout.implicitWidth : parent.width

        property real contentHeight: layout.implicitHeight
        property real contentWidth: layout.implicitWidth

        function itemAtIndex(idx: int): var {
            if (idx >= 0 && idx < rep.count) return rep.itemAt(idx);
            return null;
        }

        onContentHeightChanged: root.ensureVisible()
        onContentWidthChanged: root.ensureVisible()

        GridLayout {
            id: layout
            anchors.left: root.isHorizontal ? parent.left : undefined
            anchors.top: root.isHorizontal ? undefined : parent.top
            anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
            anchors.horizontalCenter: root.isHorizontal ? undefined : parent.horizontalCenter
            flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
            columnSpacing: root.isHorizontal ? Tokens.spacing.small : 0
            rowSpacing: root.isHorizontal ? 0 : Tokens.spacing.small

        Repeater {
            id: rep
            model: ScriptModel {
            	values: root.wsIds
            }
            onItemAdded: root.itemsRev++
            onItemRemoved: root.itemsRev++
            
            delegate: Workspace {
            	activeWsId: root.activeSpecialId
            	ws: modelData
            	monitor: root.monitor
            	offMonitorColour: Colours.palette.m3outline
            	displayType: Config.bar.workspaces.specialDisplayType
            	showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            	iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
              }
            }
        }

        Behavior on y {
            id: viewYBehavior
            enabled: !root.isHorizontal

            Anim {
                id: viewYAnim

                type: Anim.FastEffects
            }
        }
        Behavior on x {
            id: viewXBehavior
            enabled: root.isHorizontal
            Anim { id: viewXAnim; type: Anim.FastEffects }
        }
    }

    Loader {
        asynchronous: true
        anchors.fill: view
        active: Config.bar.workspaces.activeIndicator && root.activeWs !== null

        sourceComponent: ActiveIndicator {
            activeWs: root.activeWs
            mask: view
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
        }
    }

    MouseArea {
        property real startX
        property real startY
        property real startViewPos
        property bool dragging

        anchors.fill: parent

        onPressed: event => {
            startX = event.x;
            startY = event.y;
            startViewPos = root.isHorizontal ? view.x : view.y;
            dragging = false;
        }

        onPositionChanged: event => {
            const delta = root.isHorizontal ? event.x - startX : event.y - startY;
            if (!dragging && Math.abs(delta) > drag.threshold) dragging = true;
            if (dragging) {
                if (root.isHorizontal) view.x = CUtils.clamp(startViewPos + delta, -root.maxViewX, 0);
                else view.y = CUtils.clamp(startViewPos + delta, -root.maxViewY, 0);
            }
        }

        onClicked: event => {
            if (dragging) return;
            const child = layout.childAt(event.x - view.x, event.y - view.y) as Workspace;
            if (child) {
                const match = Hypr.workspaces.values.find(w => w.id === child.ws);
                if (match) Hypr.toggleSpecial(Hypr.trimWsName(match.name));
            } else {
                Hypr.toggleSpecial("special");
            }
        }
    }
}
