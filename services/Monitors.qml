pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    property bool identifying: false
    property var pendingRefreshCommands: []

    function toggleIdentification(): void {
        identifying = !identifying;
        if (identifying)
            identifyTimer.restart();
        else
            identifyTimer.stop();
    }

    function stopIdentification(): void {
        identifying = false;
        identifyTimer.stop();
    }

    function sourceMonitors(): var {
        if ((Hyprctl.monitors.length ?? 0) > 0)
            return Hyprctl.monitors;
        return Hypr.monitors.values ?? [];
    }

    // Find monitor by name
    function findMonitorByName(name: string): var {
        const monitors = sourceMonitors();
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === name)
                return monitors[i];
        }
        return null;
    }

    function findMonitorById(id: int): var {
        const monitors = sourceMonitors();
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].id == id)
                return monitors[i];
        }
        return null;
    }

    // Build the monitor string Hyprland expects:
    // NAME,WIDTHxHEIGHT@RATE,XxY,SCALE[,transform,N]
    function monitorStr(mon: var, overrideScale: real, overrideTransform: int, overrideRefreshRate: real, overrideRes: string, x: real, y: real): string {
        const scale = overrideScale >= 0 ? overrideScale : (mon.scale || 1);
        const transform = overrideTransform >= 0 ? overrideTransform : (mon.transform || 0);
        const rr = (overrideRefreshRate > 0 ? overrideRefreshRate : (mon.refreshRate || 60)).toFixed(3);
        const res = (overrideRes !== undefined && overrideRes !== "") ? overrideRes : `${mon.width}x${mon.height}`;
        let s = `${mon.name},${res}@${rr},${Math.round(x)}x${Math.round(y)},${scale}`;
        if (transform !== 0)
            s += `,transform,${transform}`;
        return s;
    }

    function luaString(value: string): string {
        return `"${value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")}"`;
    }

    function queueRefresh(command: string): void {
        pendingRefreshCommands.push(command);
        refreshTimer.restart();
    }

    function sendMonitor(mon: var, overrideScale: real, overrideTransform: int, overrideRefreshRate: real, overrideRes: string, x: real, y: real): void {
        if (!Hypr.usingLua) {
            const config = monitorStr(mon, overrideScale, overrideTransform, overrideRefreshRate, overrideRes, x, y);
            const command = `keyword monitor ${config}`;
            Hypr.extras.batchMessage([command]);
            Hyprctl.update();
            queueRefresh(command);
            return;
        }

        const scale = overrideScale >= 0 ? overrideScale : (mon.scale || 1);
        const transform = overrideTransform >= 0 ? overrideTransform : (mon.transform || 0);
        const rr = (overrideRefreshRate > 0 ? overrideRefreshRate : (mon.refreshRate || 60)).toFixed(3);
        const res = (overrideRes !== undefined && overrideRes !== "") ? overrideRes : `${mon.width}x${mon.height}`;
        let config = `hl.monitor({ output = ${luaString(mon.name)}, mode = ${luaString(`${res}@${rr}`)}, position = ${luaString(`${Math.round(x)}x${Math.round(y)}`)}, scale = ${scale}`;
        if (transform !== 0)
            config += `, transform = ${transform}`;
        config += " })";
        const command = `eval ${config}`;
        Hypr.extras.batchMessage([command]);
        Hyprctl.update();
        queueRefresh(command);
    }

    function setPosition(monitorName: string, x: real, y: real): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;
        sendMonitor(mon, mon.scale || 1, mon.transform || 0, mon.refreshRate || 60, "", x, y);
    }

    function arrange(monitorName: string, pos: string, relativeToId: int): void {
        const target = findMonitorById(relativeToId);
        const moving = findMonitorByName(monitorName);
        if (!target || !moving)
            return;

        let x = target.x ?? 0;
        let y = target.y ?? 0;

        const targetW = Math.round(target.width / (target.scale || 1));
        const targetH = Math.round(target.height / (target.scale || 1));
        const movingW = Math.round(moving.width / (moving.scale || 1));
        const movingH = Math.round(moving.height / (moving.scale || 1));

        if (pos === "left")
            x -= movingW;
        else if (pos === "right")
            x += targetW;
        else if (pos === "top")
            y -= movingH;
        else if (pos === "bottom")
            y += targetH;

        sendMonitor(moving, moving.scale || 1, moving.transform || 0, moving.refreshRate || 60, "", x, y);
    }

    function rotate(monitorName: string, angle: int): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;

        let transform = 0;
        if (angle === 90)
            transform = 1;
        else if (angle === 180)
            transform = 2;
        else if (angle === 270)
            transform = 3;

        sendMonitor(mon, mon.scale || 1, transform, mon.refreshRate || 60, "", mon.x, mon.y);
    }

    function setScale(monitorName: string, scale: real): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;
        const s = Math.max(0.5, Math.min(3.0, scale));
        sendMonitor(mon, s, mon.transform || 0, mon.refreshRate || 60, "", mon.x, mon.y);
    }

    function setRefreshRate(monitorName: string, refreshRate: real): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;
        sendMonitor(mon, mon.scale || 1, mon.transform || 0, Math.max(1, refreshRate), "", mon.x, mon.y);
    }

    function setResolution(monitorName: string, resolution: string): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;
        sendMonitor(mon, mon.scale || 1, mon.transform || 0, mon.refreshRate || 60, resolution, mon.x, mon.y);
    }

    Timer {
        id: refreshTimer

        interval: 600
        onTriggered: {
            if (root.pendingRefreshCommands.length === 0)
                return;
            const commands = root.pendingRefreshCommands;
            root.pendingRefreshCommands = [];
            Hypr.extras.batchMessage(commands);
            Hyprctl.update();
        }
    }

    // Auto-dismiss identify overlay after 5 seconds
    Timer {
        id: identifyTimer

        interval: 5000
        onTriggered: root.identifying = false
    }
}
