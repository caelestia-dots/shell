#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Simple bash script to check and will try to update your system

# Local Paths
iDIR="$HOME/.config/swaync/images"

# Check for required tools (kitty)
if ! command -v kitty &> /dev/null; then
  notify-send -i "$iDIR/error.png" "Need Kitty:" "Kitty terminal not found. Please install Kitty terminal."
  exit 1
fi

# Detect distribution and update accordingly
if command -v paru &> /dev/null || command -v yay &> /dev/null; then
  # Arch-based
  if command -v paru &> /dev/null; then
    kitty -T update paru -Syu
    notify-send -i "$iDIR/ja.png" -u low 'Arch-based system' 'has been updated.'
  else
    kitty -T update yay -Syu
    notify-send -i "$iDIR/ja.png" -u low 'Arch-based system' 'has been updated.'
  fi
elif command -v dnf &> /dev/null; then
  # Fedora-based
  kitty -T update sudo dnf update --refresh -y
  notify-send -i "$iDIR/ja.png" -u low 'Fedora system' 'has been updated.'
elif command -v apt &> /dev/null; then
  # Debian-based (Debian, Ubuntu, etc.)
  kitty -T update sudo apt update && sudo apt upgrade -y
  notify-send -i "$iDIR/ja.png" -u low 'Debian/Ubuntu system' 'has been updated.'
elif command -v zypper &> /dev/null; then
  # openSUSE-based
  kitty -T update sudo zypper dup -y
  notify-send -i "$iDIR/ja.png" -u low 'openSUSE system' 'has been updated.'
else
  # Unsupported distro
  notify-send -i "$iDIR/error.png" -u critical "Unsupported system" "This script does not support your distribution."
  exit 1
fi
