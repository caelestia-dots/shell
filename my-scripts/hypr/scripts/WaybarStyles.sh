#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for waybar styles

IFS=$'\n\t'

# Define directories
waybar_styles="$HOME/.config/waybar/style"
waybar_style="$HOME/.config/waybar/style.css"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_config="$HOME/.config/rofi/config-waybar-style.rasi"
msg=' 🎌 NOTE: Some waybar STYLES NOT fully compatible with some LAYOUTS'

# Function to display menu options
menu() {
    options=()
    while IFS= read -r file; do
        if [ -f "$waybar_styles/$file" ]; then
            options+=("$(basename "$file" .css)")
        fi
    done < <(find -L "$waybar_styles" -maxdepth 1 -type f -name '*.css' -exec basename {} \; | sort )
    
    printf '%s\n' "${options[@]}"
}

# Apply selected style
apply_style() {
    ln -sf "$waybar_styles/$1.css" "$waybar_style"
    "${SCRIPTSDIR}/Refresh.sh" &
}

# Main function
main() {
    choice=$(menu | rofi -i -dmenu -config "$rofi_config" -mesg "$msg")

    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi

    apply_style "$choice"
}

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    #exit 0
fi

main
