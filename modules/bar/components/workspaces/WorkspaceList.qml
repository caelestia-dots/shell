pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property HyprlandMonitor monitor
    required property var wsIds
    required property int activeWsId
    required property int activeIndex
    property int groupOffset: 0
    property bool isHorizontal: false
    property bool special: false
    property real maxWidth: width

    readonly property real spacing: special ? Tokens.spacing.small : Tokens.spacing.extraSmall
    readonly property real itemSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small
    readonly property real contentLength: isHorizontal ? ((view.item as Item)?.implicitWidth ?? 0) : ((view.item as LazyListView)?.layoutHeight ?? 0)
    readonly property real maxScrollOffset: Math.max(0, contentLength - (isHorizontal ? width : height))
    readonly property Workspace activeWs: workspaces[activeIndex] ?? null
    readonly property int maxHorizontalWindowIcons: {
        const max = Config.bar.workspaces.maxWindowIcons;
        if (!isHorizontal || max <= 0 || !(special ? Config.bar.workspaces.showWindowsOnSpecialWorkspaces : Config.bar.workspaces.showWindows))
            return 0;

        const count = wsIds.length;
        const labels = count * itemSize + Math.max(0, count - 1) * spacing;
        if (count === 0 || maxWidth <= labels)
            return 0;

        const demands = [];
        let high = 0;
        for (let i = 0; i < count; i++) {
            const ws = !special && Config.bar.workspaces.showUnoccupied ? groupOffset + i + 1 : wsIds[i];
            const item = workspaces[i];
            const toplevels = item?.ws === ws ? item.toplevels : Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags);
            const demand = Math.min(max, toplevels.length);
            if (demand > 0) {
                demands.push(demand);
                high = Math.max(high, demand);
            }
        }

        const available = maxWidth - labels - demands.length * Tokens.spacing.extraSmall / 2;
        const slots = Math.max(0, Math.floor(available / (itemSize * 2 / 3)));
        // Preserve a uniform cap: spare width does not favour earlier workspaces.
        let low = 0;
        while (low < high) {
            const cap = Math.floor((low + high + 1) / 2);
            let needed = 0;
            for (const demand of demands)
                needed += Math.min(demand, cap);
            if (needed <= slots)
                low = cap;
            else
                high = cap - 1;
        }
        return low;
    }

    property var workspaces: []
    property real scrollOffset: 0
    property bool animateScroll: true

    function updateItems(): void {
        workspaces = wsIds.map((_, i) => isHorizontal ? (view.item as HorizontalView)?.itemAtIndex(i) ?? null : (view.item as LazyListView)?.itemAtIndex(i) ?? null);
        Qt.callLater(ensureVisible);
    }

    function ensureVisible(animate = true): void {
        let target = scrollOffset;
        if (activeWs) {
            const start = activeWs.layoutStart;
            const end = start + activeWs.layoutLength;
            const extent = isHorizontal ? width : height;
            if (start < target)
                target = start;
            else if (end > target + extent)
                target = end - extent;
        }
        animateScroll = animate;
        scrollOffset = CUtils.clamp(target, 0, maxScrollOffset);
        animateScroll = true;
    }

    implicitWidth: isHorizontal ? contentLength : itemSize
    implicitHeight: isHorizontal ? itemSize : contentLength
    clip: true

    onWsIdsChanged: Qt.callLater(updateItems)
    onActiveWsChanged: Qt.callLater(ensureVisible)
    onContentLengthChanged: Qt.callLater(ensureVisible)
    onWidthChanged: ensureVisible(false)
    onHeightChanged: ensureVisible(false)

    ScriptModel {
        id: workspaceModel

        values: root.wsIds
    }

    Connections {
        function onRowsMoved(): void {
            Qt.callLater(root.updateItems);
        }

        target: workspaceModel
    }

    Connections {
        function onLayoutStartChanged(): void {
            Qt.callLater(root.ensureVisible);
        }

        function onLayoutLengthChanged(): void {
            Qt.callLater(root.ensureVisible);
        }

        target: root.activeWs
    }

    Component {
        id: workspaceDelegate

        Workspace {
            activeWsId: root.activeWsId
            ws: !root.special && Config.bar.workspaces.showUnoccupied ? root.groupOffset + index + 1 : modelData
            monitor: root.monitor
            isHorizontal: parent instanceof HorizontalView
            maxHorizontalWindowIcons: root.maxHorizontalWindowIcons
            offMonitorColour: root.special ? Colours.palette.m3outline : Colours.palette.m3outlineVariant
            displayType: root.special ? Config.bar.workspaces.specialDisplayType : Config.bar.workspaces.displayType
            showWindows: root.special ? Config.bar.workspaces.showWindowsOnSpecialWorkspaces : Config.bar.workspaces.showWindows
            iconRules: root.special ? GlobalConfig.bar.workspaces.specialWorkspaceIcons : GlobalConfig.bar.workspaces.workspaceIcons
            activeLabel: root.special ? "" : Config.bar.workspaces.activeLabel
            occupiedLabel: root.special ? "" : Config.bar.workspaces.occupiedLabel
            label: root.special ? "" : Config.bar.workspaces.label
        }
    }

    Item {
        id: content

        x: root.isHorizontal ? -root.scrollOffset : 0
        y: root.isHorizontal ? 0 : -root.scrollOffset
        width: root.isHorizontal ? root.contentLength : root.width
        height: root.isHorizontal ? root.height : root.contentLength

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: opacity > 0
            opacity: !root.special && Config.bar.workspaces.occupiedBg ? 1 : 0

            sourceComponent: OccupiedBg {
                workspaces: root.workspaces
                wsSpacing: root.spacing
                isHorizontal: root.isHorizontal
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            id: view

            anchors.fill: parent
            sourceComponent: root.isHorizontal ? horizontalView : verticalView
            onLoaded: Qt.callLater(root.updateItems)
        }

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: opacity > 0
            opacity: !root.special && !Config.bar.workspaces.showUnoccupied ? 1 : 0

            sourceComponent: GapMarkers {
                workspaces: root.workspaces
                wsSpacing: root.spacing
                isHorizontal: root.isHorizontal
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            asynchronous: true
            anchors.left: root.isHorizontal ? undefined : parent.left
            anchors.right: root.isHorizontal ? undefined : parent.right
            anchors.top: root.isHorizontal ? parent.top : undefined
            anchors.bottom: root.isHorizontal ? parent.bottom : undefined
            active: Config.bar.workspaces.activeIndicator && !!view.item

            sourceComponent: ActiveIndicator {
                activeWs: root.activeWs
                mask: view.item as Item
                isHorizontal: root.isHorizontal
                color: root.special ? Colours.palette.m3tertiary : Colours.palette.m3primary
                contentColour: root.special ? Colours.palette.m3onTertiary : Colours.palette.m3onPrimary
            }
        }
    }

    Component {
        id: horizontalView

        HorizontalView {}
    }

    Component {
        id: verticalView

        LazyListView {
            spacing: root.spacing
            cullDelegates: false
            model: workspaceModel
            delegate: workspaceDelegate
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects
            onItemsDirtyChanged: Qt.callLater(root.updateItems)
        }
    }

    MouseArea {
        id: mouse

        property real startAlong
        property real startOffset
        property bool dragging

        anchors.fill: parent

        onPressed: event => {
            startAlong = root.isHorizontal ? event.x : event.y;
            startOffset = root.scrollOffset;
            dragging = false;
        }

        onPositionChanged: event => {
            if (!pressed || (!root.special && !root.isHorizontal))
                return;
            const delta = (root.isHorizontal ? event.x : event.y) - startAlong;
            if (!dragging && Math.abs(delta) > drag.threshold)
                dragging = true;
            if (dragging)
                root.scrollOffset = CUtils.clamp(startOffset - delta, 0, root.maxScrollOffset);
        }

        onClicked: event => {
            if (dragging)
                return;
            const list = view.item as Item;
            const point = mapToItem(list, event.x, event.y);
            const workspace = root.isHorizontal ? list.childAt(point.x, point.y) as Workspace : (list as LazyListView).itemAt(point.x, point.y) as Workspace;
            if (root.special) {
                const match = Hypr.workspaces.values.find(w => w.id === workspace?.ws);
                Hypr.toggleSpecial(match ? Hypr.trimWsName(match.name) : "special");
            } else if (workspace) {
                if (Hypr.activeWsId !== workspace.ws)
                    Hypr.focusWorkspace(workspace.ws);
                else
                    Hypr.toggleSpecial("special");
            }
        }
    }

    Behavior on scrollOffset {
        enabled: root.animateScroll && !mouse.dragging

        Anim {}
    }

    component HorizontalView: Row {
        function itemAtIndex(index: int): Workspace {
            return repeater.itemAt(index) as Workspace;
        }

        spacing: root.spacing

        move: Transition {
            id: moveTransition

            ScriptAction {
                script: moveTransition.ViewTransition.item.layoutX = moveTransition.ViewTransition.destination.x
            }

            Anim {
                properties: "x"
            }
        }

        AnimatedRepeater {
            id: repeater

            model: workspaceModel
            delegate: workspaceDelegate
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects
            onCountChanged: Qt.callLater(root.updateItems)
        }
    }
}
