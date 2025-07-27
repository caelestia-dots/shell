# Greetd Module for Caelestia

This module provides a beautiful login GUI for greetd, styled to match the Caelestia quickshell configuration.

## Features

- Username and password input fields with the same styling as the lock screen
- Session selection dropdown (Hyprland as default)
- Auto-detection of installed desktop environments
- System control buttons (shutdown, reboot, hibernate)
- Clock display
- Weather information
- System status (battery, network)
- Smooth animations and Material You design

## Requirements

- greetd installed and configured
- greetd-client (for authentication)
- quickshell with Wayland support
- Desktop session files in `/usr/share/xsessions/` or `/usr/share/wayland-sessions/`

## Setup

1. Configure greetd to use quickshell as the greeter:

Edit `/etc/greetd/config.toml`:
```toml
[terminal]
vt = 1

[default_session]
command = "quickshell -c /home/YOUR_USER/.config/quickshell/caelestia/modules/greetd/Greetd.qml"
user = "greetd"

[initial_session]
command = "quickshell -c /home/YOUR_USER/.config/quickshell/caelestia/modules/greetd/Greetd.qml"
user = "greetd"
```

2. Ensure the greetd user has access to the quickshell configuration:
```bash
sudo usermod -a -G YOUR_USER greetd
```

3. Set appropriate permissions:
```bash
chmod -R g+rX ~/.config/quickshell
```

4. Restart greetd:
```bash
sudo systemctl restart greetd
```

## Configuration

The module respects the same configuration options as the lock module for sizing and appearance. You can adjust these in your main configuration.

## Customization

- To change the default session, modify `defaultSession` in `SessionDetector.qml`
- To customize the appearance, the module uses the same color scheme and styling as the rest of Caelestia
- Weather and status widgets can be configured through the main Caelestia configuration

## Troubleshooting

1. If authentication fails, check that greetd-client is installed and accessible
2. Ensure the greetd socket is accessible at `/run/greetd.sock`
3. Check greetd logs: `journalctl -u greetd`
4. For session startup issues, verify the desktop files in `/usr/share/xsessions/` and `/usr/share/wayland-sessions/`

## Security Notes

- The password field uses the same secure dot display as the lock screen
- Authentication is handled through greetd's secure socket
- No passwords are stored or logged

## Credits

Based on the Caelestia lock module, adapted for greetd authentication.