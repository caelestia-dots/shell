# Greetd Module for Caelestia

This module provides a beautiful login GUI for greetd, styled to match the Caelestia quickshell configuration. The module is self-contained with all necessary dependencies bundled.

## Features

- Clean, minimal login interface with Material You design
- Username and password input fields with visual feedback
- Session selection dropdown (automatically detects Hyprland and KDE Plasma)
- Visible login button with loading animation
- System control buttons (shutdown, reboot, hibernate)
- Clock display with date
- Mouse and keyboard navigation support
- Focus indicators on all interactive elements
- Self-contained module with no external dependencies

## Requirements

- greetd installed and configured
- quickshell with Wayland support
- A Wayland compositor (cage recommended for production, or use Hyprland)
- Desktop session files in `/usr/share/xsessions/` or `/usr/share/wayland-sessions/`

## Installation

### Method 1: Using the Caelestia installer (Recommended)

1. Run the installer with the greetd flag:
   ```bash
   ./install.fish --greetd
   ```

2. Follow the instructions printed by the installer to run the greetd setup script with sudo.

### Method 2: Manual Installation

1. Navigate to the greetd module directory:
   ```bash
   cd shell/modules/greetd
   ```

2. Run the installation script with sudo:
   ```bash
   sudo ./install-greetd.sh
   ```

3. The script will:
   - Back up any existing greetd configuration
   - Copy the self-contained module to `/etc/caelestia/greetd`
   - Set proper permissions for the greeter user
   - Create a launcher script at `/usr/local/bin/caelestia-greetd`
   - Create necessary directories for the greetd environment

4. Install a Wayland compositor for greetd (if not already installed):
   ```bash
   # Recommended: cage (minimal compositor)
   sudo pacman -S cage
   
   # Alternative: Use Hyprland (already installed)
   ```

5. Configure greetd by editing `/etc/greetd/config.toml`:
   ```toml
   [terminal]
   vt = 1

   [default_session]
   command = "/usr/local/bin/caelestia-greetd"
   user = "greeter"

   [initial_session]
   command = "/usr/local/bin/caelestia-greetd"
   user = "greeter"
   ```

6. Restart greetd:
   ```bash
   sudo systemctl restart greetd
   ```

## Configuration

The module uses hardcoded default configurations suitable for the greetd environment:
- Catppuccin Mocha color scheme
- System wallpaper path: `/usr/share/backgrounds/default.jpg`
- All state/cache directories use system paths instead of user paths

### Wallpapers

Place wallpapers in `/usr/share/backgrounds/`. The module will look for `default.jpg` as the default wallpaper.

### Available Sessions

The module currently shows:
- Hyprland
- KDE Plasma

These are hardcoded for reliability. In production, greetd typically provides the session list through its API.

## Development and Testing

For development, use the included test script:
```bash
cd shell/modules/greetd
./test-greetd.sh
```

This will run the greetd interface in your current session. Press Escape to exit test mode.

## Module Structure

The module is self-contained with the following structure:
```
greetd/
├── deps/                  # Bundled dependencies
│   ├── config/           # Configuration modules
│   ├── services/         # Service modules (colors, time)
│   ├── utils/            # Utility modules (paths, icons)
│   └── widgets/          # UI widget modules
├── Greetd.qml            # Main entry point
├── GreetdWindow.qml      # Window container
├── GreetdSurface.qml     # Main greeter UI
├── GreetdInput.qml       # Login form with all inputs
├── GreetdClient.qml      # Greetd authentication using Quickshell API
├── SessionDetector.qml   # Desktop session configuration
├── Backgrounds.qml       # Background shapes and styling
├── Clock.qml             # Clock and date display
├── Buttons.qml           # Power control buttons
├── install-greetd.sh     # Installation script
├── test-greetd.sh        # Development test script
└── README.md             # This file
```

## UI Improvements Made

Based on testing, the following improvements were implemented:
- Reduced clock size from 4x to 1.5x for better screen fit
- Added mouse click support to all input fields
- Added visible "Log In" button with loading animation
- Implemented focus indicators (colored borders) on all inputs
- Fixed session dropdown to open upward to prevent cutoff
- Adjusted widget height to 385px for optimal layout
- Centered text properly in session dropdown

## Troubleshooting

1. **No display**: Ensure a Wayland compositor is installed (cage or Hyprland)
2. **Authentication fails**: The Quickshell.Services.Greetd API requires the actual greetd service
3. **Module not loading**: Ensure quickshell is installed and accessible to the greeter user
4. **No wallpaper**: Place a wallpaper at `/usr/share/backgrounds/default.jpg`
5. **Sessions not showing**: Check that desktop files exist in `/usr/share/wayland-sessions/`

Check greetd logs for detailed error messages:
```bash
journalctl -u greetd -f
```

## Security Notes

- The password field uses secure dot display
- Authentication is handled through greetd's secure socket via Quickshell API
- No passwords are stored or logged
- The module runs with minimal privileges as the greeter user

## Technical Details

This module uses the Quickshell.Services.Greetd API for authentication, which provides:
- Secure communication with the greetd daemon
- Proper session launching
- Error handling and auth message management

The module is designed to work in the pre-authentication environment where:
- HOME environment variable is not available
- User paths don't exist yet
- System paths must be used for all resources

## Credits

Based on the Caelestia lock screen module, adapted and simplified for greetd authentication.