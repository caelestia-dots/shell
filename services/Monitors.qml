pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    property bool identifying: false

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

    // Safely iterate monitor data — .find() doesn't work on UntypedObjectModel
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
            if (monitors[i].id === id)
                return monitors[i];
        }
        return null;
    }

    // Build the monitor string Hyprland expects:
    // NAME,WIDTHxHEIGHT@RATE,XxY,SCALE[,transform,N]
    function monitorStr(mon: var, overrideScale: real, overrideTransform: int, overrideRefreshRate: real, overrideRes: string): string {
        const scale = overrideScale >= 0 ? overrideScale : (mon.scale || 1);
        const transform = overrideTransform >= 0 ? overrideTransform : (mon.transform || 0);
        const rr = (overrideRefreshRate > 0 ? overrideRefreshRate : (mon.refreshRate || 60)).toFixed(3);
        const res = (overrideRes !== undefined && overrideRes !== "") ? overrideRes : `${mon.width}x${mon.height}`;
        let s = `${mon.name},${res}@${rr},${mon.x}x${mon.y},${scale}`;
        if (transform !== 0)
            s += `,transform,${transform}`;
        return s;
    }

    // Use batchMessage (hyprctl keyword), NOT dispatch (hyprctl dispatch)
    // "keyword" is a config command, not a dispatcher action.
    function sendKeyword(monStr: string): void {
        Hypr.extras.batchMessage([`keyword monitor ${monStr}`]);
        Hyprctl.update();
    }

    function arrange(monitorName: string, pos: string, relativeToId: int): void {
        const target = findMonitorById(relativeToId);
        const moving = findMonitorByName(monitorName);
        if (!target || !moving)
            return;

        let x = target.x;
        let y = target.y;

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

        const scale = moving.scale || 1;
        const transform = moving.transform || 0;
        const rr = (moving.refreshRate || 60).toFixed(3);

        let s = `${moving.name},${moving.width}x${moving.height}@${rr},${Math.round(x)}x${Math.round(y)},${scale}`;
        if (transform !== 0)
            s += `,transform,${transform}`;

        sendKeyword(s);
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

        sendKeyword(monitorStr(mon, mon.scale || 1, transform, mon.refreshRate || 60, ""));
    }

    function setScale(monitorName: string, scale: real): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;
        const s = Math.max(0.5, Math.min(3.0, scale));
        sendKeyword(monitorStr(mon, s, mon.transform || 0, mon.refreshRate || 60, ""));
    }

    function setRefreshRate(monitorName: string, refreshRate: real): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;
        sendKeyword(monitorStr(mon, mon.scale || 1, mon.transform || 0, Math.max(1, refreshRate), ""));
    }

    function setResolution(monitorName: string, resolution: string): void {
        const mon = findMonitorByName(monitorName);
        if (!mon)
            return;
        sendKeyword(monitorStr(mon, mon.scale || 1, mon.transform || 0, mon.refreshRate || 60, resolution));
    }

    // Auto-dismiss identify overlay after 5 seconds
    Timer {
        id: identifyTimer

        interval: 5000
        onTriggered: root.identifying = false
    }
}
