#!/bin/bash
# Test script for greetd module in development mode

echo "Starting greetd module in test mode..."
echo "This will show the UI but won't actually authenticate."
echo "Press Ctrl+C to exit."
echo ""

# Set test environment
export QT_QPA_PLATFORM=wayland
export GREETD_TEST_MODE=1

# Run quickshell with the greetd module
quickshell -p "$(dirname "$0")/Greetd.qml"