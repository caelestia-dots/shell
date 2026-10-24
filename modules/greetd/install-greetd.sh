#!/bin/bash
# Caelestia Greetd Module Installation Script
# This script helps set up the self-contained greetd module

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREETD_MODULE_DIR="$SCRIPT_DIR"
SYSTEM_GREETD_DIR="/etc/caelestia/greetd"
GREETD_CONFIG="/etc/greetd/config.toml"
GREETD_LAUNCHER="/usr/local/bin/caelestia-greetd"

echo "=== Caelestia Greetd Module Installer ==="
echo
echo "This installer will set up the Caelestia greetd login manager."
echo "If greetd is already configured, your existing configuration will be backed up."
echo

# Check if running with appropriate permissions
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs to be run with sudo to configure greetd."
    echo "Please run: sudo $0"
    exit 1
fi

# Check if greetd is installed
if ! command -v greetd &> /dev/null; then
    echo "Error: greetd is not installed on this system."
    echo "Please install greetd first using your package manager."
    exit 1
fi

# Check if quickshell is installed
if ! command -v quickshell &> /dev/null; then
    echo "Error: quickshell is not installed on this system."
    echo "Please install quickshell first."
    exit 1
fi

# Check if cage is installed
if ! command -v cage &> /dev/null; then
    echo "Warning: cage is not installed. Installing it is highly recommended."
    echo "Install with: sudo pacman -S cage"
    echo
fi

# Backup existing configuration if it exists
if [ -d "$SYSTEM_GREETD_DIR" ]; then
    BACKUP_DIR="/etc/caelestia/greetd.backup.$(date +%Y%m%d_%H%M%S)"
    echo "1. Backing up existing greetd configuration to $BACKUP_DIR..."
    cp -r "$SYSTEM_GREETD_DIR" "$BACKUP_DIR"
    echo "   Backup created successfully."
fi

# Also backup greetd config if it exists
if [ -f "$GREETD_CONFIG" ]; then
    GREETD_CONFIG_BACKUP="${GREETD_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "   Backing up greetd config to $GREETD_CONFIG_BACKUP..."
    cp "$GREETD_CONFIG" "$GREETD_CONFIG_BACKUP"
fi

echo
echo "2. Creating system directory for greetd module..."
mkdir -p "$SYSTEM_GREETD_DIR"

echo "3. Copying self-contained greetd module to system location..."
cp -r "$GREETD_MODULE_DIR"/* "$SYSTEM_GREETD_DIR/"

echo "4. Setting permissions..."
# The greeter user needs to read these files
chown -R greeter:greeter "$SYSTEM_GREETD_DIR"
chmod -R 755 "$SYSTEM_GREETD_DIR"

# Remove any old auth script if it exists
if [ -f "$SYSTEM_GREETD_DIR/greetd-auth.sh" ]; then
    echo "   Removing old auth script..."
    rm "$SYSTEM_GREETD_DIR/greetd-auth.sh"
fi

echo "5. Installing systemd tmpfiles configuration..."
cp "$GREETD_MODULE_DIR/tmpfiles.conf" /etc/tmpfiles.d/caelestia-greetd.conf

# Apply the tmpfiles configuration immediately
systemd-tmpfiles --create /etc/tmpfiles.d/caelestia-greetd.conf

echo "6. Installing launcher script..."
cp "$GREETD_MODULE_DIR/caelestia-greetd" "$GREETD_LAUNCHER"

chmod +x "$GREETD_LAUNCHER"

echo "7. Creating recommended directories..."
mkdir -p /var/lib/caelestia-greetd/state
mkdir -p /var/cache/caelestia-greetd
mkdir -p /var/log/caelestia-greetd
chown -R greeter:greeter /var/lib/caelestia-greetd
chown -R greeter:greeter /var/cache/caelestia-greetd
chown -R greeter:greeter /var/log/caelestia-greetd

# Check if default wallpaper directory exists
if [ ! -d "/usr/share/backgrounds" ]; then
    echo "   Creating wallpaper directory..."
    mkdir -p /usr/share/backgrounds
fi

echo
echo "=== Installation Complete ==="
echo
echo "To use Caelestia as your greetd greeter, update your greetd config:"
echo
echo "Edit $GREETD_CONFIG and set:"
echo
echo "[default_session]"
echo "command = \"$GREETD_LAUNCHER\""
echo "user = \"greeter\""
echo
echo "Then restart greetd:"
echo "sudo systemctl restart greetd"
echo
echo "Optional: Place wallpapers in /usr/share/backgrounds/"
echo "The greeter will use /usr/share/backgrounds/default.jpg if available."
echo
echo "For debugging, you can test the greeter in a window:"
echo "sudo -u greeter $GREETD_LAUNCHER"
echo
echo "Features:"
echo "- Username pre-population (last logged-in user)"
echo "- Smart focus (password field if username is filled)"
echo "- Debug logging to /var/log/caelestia-greetd/"
echo
echo "Note: The runtime directory /run/greeter will be created automatically"
echo "by systemd on boot thanks to the tmpfiles configuration."
echo