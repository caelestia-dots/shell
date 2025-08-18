# Notification Setup Guide

This guide explains how to configure notifications to use Quickshell's notification server exclusively, preventing conflicts with other notification daemons.

## Problem

Multiple notification daemons can run simultaneously, causing conflicts where some notifications show in your previous rice (like swaync, dunst, mako) and others show in Quickshell. This creates inconsistent notification behavior.

## Solution: Use Quickshell Notifications Only

### Step 1: Stop Conflicting Notification Daemons

First, identify what notification daemons are running:

```bash
# Check for common notification daemons
pgrep -fl "dunst|mako|swaync"

# Check systemd services
systemctl --user list-units --type=service | grep -E "(dunst|mako|notification|notify|swaync)"
```

### Step 2: Disable the Conflicting Daemon

For **swaync** (SwayNotificationCenter):
```bash
# Stop the running daemon
killall swaync

# Disable from auto-starting
systemctl --user disable swaync

# Mask the service (prevents it from being started)
systemctl --user mask swaync
```

For **dunst**:
```bash
# Stop the running daemon
killall dunst

# Disable from auto-starting
systemctl --user disable dunst

# Mask the service
systemctl --user mask dunst
```

For **mako**:
```bash
# Stop the running daemon
killall mako

# Disable from auto-starting
systemctl --user disable mako

# Mask the service
systemctl --user mask mako
```

### Step 3: Verify Quickshell Notifications

1. Restart Quickshell:
   ```bash
   # If using the caelestia command
   caelestia shell restart
   
   # Or if running directly
   qs -c caelestia
   ```

2. Test notifications:
   ```bash
   notify-send "Test" "This should appear in Quickshell notifications"
   ```

## Configuration

Quickshell notification settings are in:
- **Config file**: `config/NotifsConfig.qml`
- **Service**: `services/Notifs.qml`
- **User config**: `~/.config/caelestia/shell.json`

### Key Settings

In `config/NotifsConfig.qml`:
```qml
JsonObject {
    property bool expire: true                    // Auto-expire notifications
    property int defaultExpireTimeout: 5000      // Default timeout (5 seconds)
    property real clearThreshold: 0.3            // Swipe threshold to clear
    property int expandThreshold: 20             // Character limit before expand
    property bool actionOnClick: false           // Click to open notification actions
    property int groupPreviewNum: 3              // Number of notifications to preview in groups
}
```

## Troubleshooting

### Notifications Still Not Working?

1. **Check if Quickshell notification server is running**:
   ```bash
   # Look for quickshell process
   pgrep -fl quickshell
   ```

2. **Check D-Bus notification interface**:
   ```bash
   # See what's providing notifications
   busctl --user list | grep notification
   ```

3. **Test D-Bus directly**:
   ```bash
   busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications Notify susssasa{sv}i "test" 0 "" "Test Title" "Test body" as 0 a{sv} 5000
   ```

### Autostart Conflicts

Check these locations for conflicting autostart entries:
- `~/.config/autostart/`
- `~/.config/hypr/hyprland.conf` (exec-once lines)
- `~/.config/sway/config` (if using Sway)

Remove or comment out any lines that start notification daemons.

## Reverting Changes (If Needed)

If you want to go back to using your previous notification daemon:

### Re-enable swaync:
```bash
# Unmask the service
systemctl --user unmask swaync

# Enable for auto-start
systemctl --user enable swaync

# Start immediately
systemctl --user start swaync
```

### Re-enable dunst:
```bash
# Unmask the service
systemctl --user unmask dunst

# Enable for auto-start
systemctl --user enable dunst

# Start immediately
systemctl --user start dunst
```

### Re-enable mako:
```bash
# Unmask the service
systemctl --user unmask mako

# Enable for auto-start
systemctl --user enable mako

# Start immediately
systemctl --user start mako
```

After re-enabling your preferred daemon, you may want to stop Quickshell or disable its notification server by modifying the `services/Notifs.qml` file.

## Notes

- Quickshell's notification server supports actions, images, markup, and hyperlinks
- The notification server setting `keepOnReload: false` in `services/Notifs.qml` means notifications won't persist across Quickshell restarts
- Notifications are cleared with the keybind defined in `CustomShortcut` or via IPC: `caelestia notifs clear`