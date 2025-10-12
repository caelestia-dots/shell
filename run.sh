#!/usr/bin/env bash
set -e

# Make sure .local exists
mkdir -p "$PWD/.local"

# Configure build if not already done
if [ ! -d build ]; then
    cmake -S . -B build \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_CXX_COMPILER=clazy \
      -DCMAKE_INSTALL_PREFIX=$PWD/.local \
      -DINSTALL_LIBDIR=lib/caelestia \
      -DINSTALL_QMLDIR=lib/qt6/qml \
      -DINSTALL_QSCONFDIR=etc/xdg/quickshell/caelestia \
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
fi

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
    export QML2_IMPORT_PATH="$PWD/.local/lib/qt6/qml:$QML2_IMPORT_PATH"
    QS_CONFIG_NAME=caelestia \
    XDG_CONFIG_DIRS="$PWD/.local/etc/xdg" \
    quickshell &
}

export -f run_quickshell

# Find all QML, CPP, and header files, then watch them
find \
    "$PWD" \
    -name '*.qml' -o -name '*.cpp' -o -name '*.hpp' \
| grep -v '^./build' \
| entr -r bash -c run_quickshell
