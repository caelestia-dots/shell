#!/usr/bin/env bash
set -e

# Make sure .local exists
mkdir -p "$PWD/.local/usr"

# Full build + install once before entering the loop
cmake --build build
cmake --install build

# Function to rebuild + restart quickshell
run_quickshell() {
    cmake --build build
    cmake --install build

    # Kill old quickshell if running
    pkill -x quickshell || true

    # Relaunch
    QS_CONFIG_NAME=caelestia \
    XDG_CONFIG_DIRS="$PWD/.local/usr/etc/xdg" \
    quickshell &
}

export -f run_quickshell

# Find all QML, CPP, and header files, then watch them
find \
    "$PWD/caelestia" \
    "$PWD/plugin" \
    -name '*.qml' -o -name '*.cpp' -o -name '*.hpp' \
| entr -r bash -c run_quickshell
