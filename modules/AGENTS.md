# Modules — Agent Guide

Feature modules. Each subdirectory is a self-contained UI feature with its own components and state.

## Module structure

Every module follows a consistent pattern:

```
modules/<name>/
├── <Name>.qml              # Entry point — same name as directory, PascalCase
├── Content.qml             # Main content (common pattern for drawer-based modules)
├── Wrapper.qml             # Window/positioning wrapper (if applicable)
├── components/             # Module-specific sub-components
│   └── *.qml
└── popouts/                # Expandable panels (bar module only)
    └── *.qml
```

## Module inventory

| Module | Entry point | Window type | Description |
|--------|-------------|-------------|-------------|
| `bar` | `Bar.qml` via `BarWrapper.qml` | Drawer-managed | Vertical side bar with workspaces, clock, tray, status icons |
| `dashboard` | `Dash.qml` | Drawer-managed | System dashboard with media, performance, weather |
| `sidebar` | `Content.qml` | Drawer-managed | Notification sidebar |
| `launcher` | `Content.qml` | Drawer-managed | App launcher with search, actions, wallpaper picker |
| `session` | `Content.qml` | Drawer-managed | Session controls (shutdown, reboot, logout) |
| `notifications` | `Wrapper.qml` | Independent | Notification popups |
| `osd` | `Wrapper.qml` | Independent | On-screen display (volume, brightness) |
| `utilities` | `Content.qml` | Drawer-managed | Quick toggles, VPN, recordings |
| `controlcenter` | `ControlCenter.qml` | Detached from bar | Full settings panel with nav rail + panes |
| `background` | `Background.qml` | Per-screen | Wallpaper, desktop clock, audio visualiser |
| `drawers` | `Drawers.qml` | Per-screen | Hosts all drawer-based modules per screen |
| `lock` | `Lock.qml` | Session lock | Lock screen (PAM, fingerprint) |
| `areapicker` | `AreaPicker.qml` | Overlay | Screen region selection |
| `windowinfo` | (detached) | Detached from bar | Window details overlay |

## Instantiation

Modules are instantiated in two ways:

1. **Directly in `shell.qml`**: `Background`, `Drawers`, `AreaPicker`, `Lock`, `ConfigToasts`, `Shortcuts`, `BatteryMonitor`, `IdleMonitors`
2. **Inside `Drawers.qml`**: Per-screen instances via `Variants` — this is where the bar, dashboard, sidebar, launcher, session, notifications, osd, and utilities are created

## Drawer system

Most modules live inside the drawer system (`modules/drawers/`):

- `Drawers.qml` creates a `ContentWindow` per screen using `Variants`
- `ContentWindow.qml` is a `PanelWindow` that hosts all drawer modules and manages their visibility
- Drawers slide in/out with animations, driven by `Visibilities` service
- `Exclusions.qml` handles exclusive zones per module

## Bar popouts

The bar module has a special popout system (`modules/bar/popouts/`):

- `PopoutState.qml` — minimal state object (currentName, hasCurrent)
- `Wrapper.qml` — manages popout positioning, focus grab, keyboard handling, detached mode
- `Content.qml` — hosts all popout `Loader`s, each gated by `shouldBeActive` matching `popoutState.currentName`
- Individual popouts: `Audio.qml`, `Battery.qml`, `Bluetooth.qml`, `Network.qml`, etc.

Popout pattern:
```qml
component Popout: Loader {
    required property string name
    readonly property bool shouldBeActive: popouts.currentName === name

    active: false
    opacity: 0
    scale: 0.8

    states: State {
        name: "active"
        when: shouldBeActive
        PropertyChanges { opacity: 1; scale: 1; active: true }
    }

    transitions: [ /* Anim on opacity, scale */ ]
}
```

## Adding a new module

1. Create `modules/<name>/` directory
2. Add entry point `<Name>.qml`
3. If drawer-based: add to `ContentWindow.qml` in `modules/drawers/`
4. If standalone: instantiate in `shell.qml`
5. If it needs config: add config class in `plugin/src/Caelestia/Config/` and expose via `GlobalConfig`
6. Module-specific components go in `modules/<name>/components/`
7. Shared data logic goes in `services/` as a singleton, not inside the module
