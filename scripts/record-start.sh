#!/usr/bin/env bash
# Start-only wrapper: never toggle-stop an in-progress recording.
# `caelestia record` without flags stops gpu-screen-recorder if it is already running,
# which races when a UI click is delivered twice (menu item + SplitButton underneath).
set -euo pipefail

# Prefer XDG Videos (e.g. ~/Vídeos); fall back to the Spanish folder name.
videos_dir="${XDG_VIDEOS_DIR:-}"
if [[ -z "$videos_dir" && -f "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" ]]; then
    # shellcheck disable=SC1090
    videos_dir="$(. "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" >/dev/null; echo "${XDG_VIDEOS_DIR:-}")"
fi
videos_dir="${videos_dir:-$HOME/Vídeos}"
export CAELESTIA_RECORDINGS_DIR="${CAELESTIA_RECORDINGS_DIR:-$videos_dir/Videocapturas de pantalla}"
mkdir -p "$CAELESTIA_RECORDINGS_DIR"

if pidof gpu-screen-recorder >/dev/null 2>&1; then
    exit 0
fi
exec caelestia record "$@"
