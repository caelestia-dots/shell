# Services — Agent Guide

Singleton data layer. Every file here is a `pragma Singleton` that owns data-fetching logic and exposes reactive properties. No visual elements.

## Pattern

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io        // for Process, StdioCollector
import Caelestia.Config     // if reading config

Singleton {
    id: root

    readonly property string someValue: "..."

    // External process polling
    Process {
        id: proc
        command: ["some-command"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.someValue = this.text.trim()
        }
    }

    // IPC handler for shell commands (caelestia shell <target> <method>)
    IpcHandler {
        target: "myservice"
        function doSomething(): void { /* ... */ }
    }
}
```

## Key services

| Service | Purpose | Data source |
|---------|---------|-------------|
| `Audio` | Volume, mute, sink/source selection | `Quickshell.Services.Pipewire` + `Caelestia.Services` (cava, beat tracker) |
| `Brightness` | Screen brightness | `brightnessctl` / `ddcutil` via Process |
| `Colours` | Material 3 color palette, transparency | `Caelestia` image analyser + scheme JSON files |
| `Hypr` | Hyprland state (workspaces, monitors, toplevels) | `Quickshell.Hyprland` singleton wrapper |
| `Network` / `Nmcli` | Network state, wifi scanning | `nmcli` via Process |
| `Notifs` / `NotifData` | Notification server + history | `Quickshell.Services.Notifications` |
| `Players` | MPRIS media players | `Quickshell.Services.Mpris` |
| `Screens` | Screen list with config-driven filtering | `Quickshell.screens` + `Caelestia.Config` |
| `SystemUsage` | CPU, memory, GPU, temperature | `/proc/stat`, `/proc/meminfo`, `sensors` via Process |
| `Time` | Formatted time/date | `Quickshell.SystemClock` |
| `Visibilities` | Per-screen drawer visibility state | `PersistentProperties` |
| `Wallpapers` | Wallpaper list and current wallpaper | File watchers + state files |
| `Weather` | Weather data | HTTP requests via `Caelestia` requests module |

## Conventions

- All singletons use `Singleton` as root type (from Quickshell)
- Access from anywhere by filename: `Audio.volume`, `Time.format("HH:mm")`, `Colours.palette.m3primary`
- Use `readonly property` for derived/computed state
- Use `Process` + `StdioCollector` for external command output, `Timer` for polling intervals
- Use `IpcHandler` to expose methods to the CLI (`caelestia shell <target> <method>`)
- Config values read via `GlobalConfig.*` (global) or `Config.*` (per-monitor via attached property)
