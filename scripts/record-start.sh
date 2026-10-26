#!/usr/bin/env bash
# Start-only wrapper: never toggle-stop an in-progress recording.
# `caelestia record` without flags stops gpu-screen-recorder if it is already running,
# which races when a UI click is delivered twice (menu item + SplitButton underneath).
set -euo pipefail
if pidof gpu-screen-recorder >/dev/null 2>&1; then
    exit 0
fi
exec caelestia record "$@"
