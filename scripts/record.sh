#!/usr/bin/env bash
# Run `caelestia record` with the configured recordings directory.
# Used for stop/pause so the final file lands in the same folder as start.
set -euo pipefail

videos_dir="${XDG_VIDEOS_DIR:-}"
if [[ -z "$videos_dir" && -f "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" ]]; then
    # shellcheck disable=SC1090
    videos_dir="$(. "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" >/dev/null; echo "${XDG_VIDEOS_DIR:-}")"
fi
videos_dir="${videos_dir:-$HOME/Vídeos}"
export CAELESTIA_RECORDINGS_DIR="${CAELESTIA_RECORDINGS_DIR:-$videos_dir/Videocapturas de pantalla}"
mkdir -p "$CAELESTIA_RECORDINGS_DIR"

exec caelestia record "$@"
