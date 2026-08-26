pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Display")

    property int monitorIndex: 0
    readonly property var monitor: Hypr.monitors.values[Math.min(root.monitorIndex, Hypr.monitors.values.length - 1)] ?? null

    function uniqueResolutions(mon) {
        if (!mon)
            return [];
        const modes = mon.lastIpcObject.availableModes ?? [];
        const seen = new Set();
        const list = [];
        for (const m of modes) {
            const res = m.split("@")[0];
            if (!seen.has(res)) {
                seen.add(res);
                list.push(res);
            }
        }
        list.sort((a, b) => {
            const [aw, ah] = a.split("x").map(Number);
            const [bw, bh] = b.split("x").map(Number);
            return bw * ah === ah * bw ? 0 : (bw * ah) - (aw * ah);
        });
        return list;
    }

    function refreshesForRes(mon, res) {
        if (!mon)
            return [];
        const modes = mon.lastIpcObject.availableModes ?? [];
        const list = [];
        for (const m of modes) {
            const parts = m.split("@");
            if (parts[0] === res)
                list.push(Math.round(parseFloat(parts[1])));
        }
        list.sort((a, b) => b - a);
        return [...new Set(list)];
    }

    function currentRes(mon) {
        return mon ? `${mon.width}x${mon.height}` : "";
    }

    function currentRefresh(mon) {
        return mon ? Math.round(mon.lastIpcObject.refreshRate ?? 0) : 0;
    }

    function applyMonitor(mon, res, refresh, scale) {
        if (!mon)
            return;
        const cmd = `keyword monitor ${mon.name},${res}@${refresh},${mon.x}x${mon.y},${scale}`;
        Hypr.extras.batchMessage([cmd]);
    }

    function buildItems(strs) {
        const items = [];
        for (const s of strs)
            items.push(menuItemComp.createObject(root, {
                text: s
            }));
        return items;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Component {
            id: menuItemComp

            MenuItem {}
        }

        SectionHeader {
            first: true
            text: root.monitor ? (root.monitor.description || root.monitor.name) : qsTr("No monitors detected")
        }

        SelectRow {
            visible: Hypr.monitors.values.length > 1
            first: true
            label: qsTr("Monitor")
            menuItems: root.buildItems(Hypr.monitors.values.map(m => m.name))
            active: menuItems[root.monitorIndex] ?? null
            onSelected: item => root.monitorIndex = Hypr.monitors.values.findIndex(m => m.name === item.text)
        }

        SelectRow {
            readonly property var resOptions: root.uniqueResolutions(root.monitor)

            first: !(Hypr.monitors.values.length > 1)
            label: qsTr("Resolution")
            subtext: qsTr("Requires a supported mode to be listed by Hyprland")
            menuItems: root.buildItems(resOptions)
            active: menuItems.find(i => i.text === root.currentRes(root.monitor)) ?? null
            onSelected: item => {
                const refreshes = root.refreshesForRes(root.monitor, item.text);
                root.applyMonitor(root.monitor, item.text, refreshes[0] ?? root.currentRefresh(root.monitor), root.monitor.scale);
            }
        }

        SelectRow {
            readonly property var refreshOptions: root.refreshesForRes(root.monitor, root.currentRes(root.monitor))

            label: qsTr("Refresh rate")
            menuItems: root.buildItems(refreshOptions.map(r => r + " Hz"))
            active: menuItems.find(i => i.text === (root.currentRefresh(root.monitor) + " Hz")) ?? null
            onSelected: item => root.applyMonitor(root.monitor, root.currentRes(root.monitor), parseInt(item.text), root.monitor.scale)
        }

        StepperRow {
            last: true
            label: qsTr("Scale")
            subtext: qsTr("Fractional scaling, e.g. 1.25 for 125%")
            value: root.monitor ? Math.round(root.monitor.scale * 100) : 100
            from: 50
            to: 300
            stepSize: 5
            onMoved: v => root.applyMonitor(root.monitor, root.currentRes(root.monitor), root.currentRefresh(root.monitor), v / 100)
        }
    }
}
