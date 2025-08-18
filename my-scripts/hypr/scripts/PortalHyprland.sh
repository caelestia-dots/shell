#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For manually starting xdg-desktop-portal-hyprland

sleep 1
killall xdg-desktop-portal-hyprland
killall xdg-desktop-portal-wlr
killall xdg-desktop-portal-gnome
killall xdg-desktop-portal
sleep 1
/usr/lib/xdg-desktop-portal-hyprland &
/usr/libexec/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
/usr/libexec/xdg-desktop-portal &

