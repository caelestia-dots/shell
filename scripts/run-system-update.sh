#!/usr/bin/env bash
# Noninteractive system update for the bar/Nexus installers.
# Reads the sudo password from stdin (first line), then elevates via SUDO_ASKPASS.
set -euo pipefail

ASKPASS="${XDG_RUNTIME_DIR:-/tmp}/caelestia-updates-askpass"
PWFILE="${ASKPASS}.pw"

cleanup() {
    rm -f "$ASKPASS" "$PWFILE"
}
trap cleanup EXIT

IFS= read -r PASSWORD || true
if [[ -z "${PASSWORD}" ]]; then
    echo "Password required" >&2
    exit 2
fi

umask 077
printf '%s\n' "$PASSWORD" >"$PWFILE"
cat >"$ASKPASS" <<EOF
#!/bin/sh
exec cat "$PWFILE"
EOF
chmod 700 "$ASKPASS"
chmod 600 "$PWFILE"
export SUDO_ASKPASS="$ASKPASS"
PASSWORD=""

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
    echo "→ ${wrapper} -Syu --noconfirm --sudoflags=-A ${aur_flags[*]-}"
    "$wrapper" -Syu --noconfirm --sudoflags=-A ${aur_flags[@]+"${aur_flags[@]}"}
elif [[ "$do_arch" -eq 1 ]]; then
    echo "→ sudo -A pacman -Syu --noconfirm"
    sudo -A pacman -Syu --noconfirm
fi

if [[ "$do_flatpak" -eq 1 ]]; then
    echo "→ flatpak update -y ${flatpak_flags[*]-}"
    flatpak update -y ${flatpak_flags[@]+"${flatpak_flags[@]}"}
fi

echo "Update finished."
