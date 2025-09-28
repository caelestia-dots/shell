#!/usr/bin/env bash
set -e

# Configure with system prefix
rm -rf build
cmake -S . -B build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_CXX_COMPILER=clazy \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DINSTALL_LIBDIR=lib/caelestia \
  -DINSTALL_QMLDIR=lib/qt6/qml \
  -DINSTALL_QSCONFDIR=etc/xdg/quickshell/caelestia \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build
cmake --build build

# Install system-wide (requires sudo)
sudo cmake --install build

echo "✅ Caelestia installed system-wide into /usr"
echo "👉 After reboot, run QuickShell with:"
echo "   QS_CONFIG_NAME=caelestia quickshell"
