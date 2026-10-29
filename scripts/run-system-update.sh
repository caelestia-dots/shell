#!/usr/bin/env bash
# Noninteractive system update for the bar/Nexus installers.
# The sudo password arrives via stdin (first line) and is kept ONLY in this
# process' memory: every elevated step refreshes the timestamp with
# `sudo -S -v` first. No password file is ever written to disk here — the
# previous askpass temp file lived for the whole installation, which is
# recoverable from memory dumps on crash.
set -euo pipefail

IFS= read -r PASSWORD || true
if [[ -z "${PASSWORD}" ]]; then
    echo "Password required" >&2
    exit 2
fi

refresh_sudo() {
    # Re-validate so later `sudo -A` calls ride on the fresh timestamp; if it
    # lapsed again mid-step, that step fails visibly in the install log.
    printf '%s\n' "$PASSWORD" | sudo -S -v 2>/dev/null || {
        echo "Authentication failed" >&2
        exit 2
    }
}

do_aur=0
do_arch=0
do_flatpak=0
wrapper="yay"
aur_flags=()
flatpak_flags=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --aur)
            do_aur=1
            wrapper="${2:-yay}"
            shift 2
            ;;
        --arch)
            do_arch=1
            shift
            ;;
        --flatpak)
            do_flatpak=1
            shift
            ;;
        --aur-flag)
            aur_flags+=("$2")
            shift 2
            ;;
        --flatpak-flag)
            flatpak_flags+=("$2")
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [[ "$do_aur" -eq 1 ]]; then
    refresh_sudo
    echo "→ ${wrapper} -Syu --noconfirm --sudoflags=-A ${aur_flags[*]-}"
    "$wrapper" -Syu --noconfirm --sudoflags=-A ${aur_flags[@]+"${aur_flags[@]}"}
fi

if [[ "$do_arch" -eq 1 ]]; then
    refresh_sudo
    echo "→ sudo -A pacman -Syu --noconfirm"
    sudo -A pacman -Syu --noconfirm
fi

if [[ "$do_flatpak" -eq 1 ]]; then
    echo "→ flatpak update -y ${flatpak_flags[*]-}"
    flatpak update -y ${flatpak_flags[@]+"${flatpak_flags[@]}"}
fi

echo "Update finished."
