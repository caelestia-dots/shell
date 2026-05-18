pragma Singleton

import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    property var items: []

    function reload(): void {
        updateItems();
    }

    function updateItems(): void {
        const windows = [];
        for (const client of Hyprland.toplevels.values) {
            windows.push({
                address: client.address,
                title: client.title || "",
                class: client.lastIpcObject?.class || "",
                workspace: client.workspace?.name || "",
                monitor: client.monitor?.name || "",
                wayland: client.wayland,
                size: client.lastIpcObject?.size || [0, 0],
                at: client.lastIpcObject?.at || [0, 0]
            });
        }
        items = windows;
    }

    function query(search: string): var {
        if (!search) return items;
        const lower = search.toLowerCase();
        return items.filter(w =>
            w.title.toLowerCase().includes(lower) ||
            w.class.toLowerCase().includes(lower)
        );
    }

    function focusWindow(address: string): void {
        Hyprland.dispatch(`focuswindow address:0x${address}`);
    }

    Component.onCompleted: {
        updateItems();
        Hyprland.toplevels.onValuesChanged.connect(updateItems);
    }
}