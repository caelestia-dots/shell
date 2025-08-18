#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for waybar layout or configs

IFS=$'\n\t'

# Define directories
waybar_layouts="$HOME/.config/waybar/configs"
waybar_config="$HOME/.config/waybar/config"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_config="$HOME/.config/rofi/config-waybar-layout.rasi"
msg=' 🎌 NOTE: Some waybar LAYOUT NOT fully compatible with some STYLES'

# Function to display menu options
menu() {
    options=()
    while IFS= read -r file; do
        options+=("$(basename "$file")")
    done < <(find -L "$waybar_layouts" -maxdepth 1 -type f -exec basename {} \; | sort )

    printf '%s\n' "${options[@]}"
}

# Apply selected configuration
apply_config() {
    ln -sf "$waybar_layouts/$1" "$waybar_config"
    "${SCRIPTSDIR}/Refresh.sh" &
}

# Main function
main() {
    choice=$(menu | rofi -i -dmenu -config "$rofi_config" -mesg "$msg")

    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi

    case $choice in
        "no panel")
            pgrep -x "waybar" && pkill waybar || true
            ;;
        *)
            apply_config "$choice"
            ;;
    esac
}

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    #exit 0
fi

main
