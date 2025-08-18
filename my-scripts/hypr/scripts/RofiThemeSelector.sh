#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for adding a selected theme to the Rofi config

IFS=$'\n\t'

# Define directories and variables
rofi_theme_dir="$HOME/.config/rofi/themes"
rofi_config_file="$HOME/.config/rofi/config.rasi"
SED=$(which sed)
iDIR="$HOME/.config/swaync/images"
rofi_theme="$HOME/.config/rofi/config-rofi-theme.rasi"

# Function to display menu options
menu() {
    options=()
    while IFS= read -r file; do
        options+=("$file")
    done < <(find -L "$rofi_theme_dir" -maxdepth 1 -type f -exec basename {} \; | sort -V)

    printf '%s\n' "${options[@]}"
}

# Function to add or update theme in the config.rasi
add_theme_to_config() {
    local theme_name="$1"
    local theme_path="$rofi_theme_dir/$theme_name"
        
    # if config in $HOME to write as $HOME 
    if [[ "$theme_path" == $HOME/* ]]; then
        theme_path_with_tilde="~${theme_path#$HOME}"
    else
        theme_path_with_tilde="$theme_path"
    fi

    # If no @theme is in the file, add it
    if ! grep -q '^\s*@theme' "$rofi_config_file"; then
        echo -e "\n\n@theme \"$theme_path_with_tilde\"" >> "$rofi_config_file"
        echo "Added @theme \"$theme_path_with_tilde\" to $rofi_config_file"
    else
        $SED -i "s/^\(\s*@theme.*\)/\/\/\1/" "$rofi_config_file"
        echo -e "@theme \"$theme_path_with_tilde\"" >> "$rofi_config_file"
        echo "Updated @theme line to $theme_path_with_tilde"
    fi

    # Ensure no more than max # of lines with //@theme lines
    max_line="9"
    total_lines=$(grep -c '^\s*//@theme' "$rofi_config_file")

    if [ "$total_lines" -gt "$max_line" ]; then
        excess=$((total_lines - max_line))
        # Remove the oldest or the very top //@theme lines
        for i in $(seq 1 "$excess"); do
            $SED -i '0,/^\s*\/\/@theme/ { /^\s*\/\/@theme/ {d; q; }}' "$rofi_config_file"
        done
        echo "Removed excess //@theme lines"
    fi
}

# Main function
main() {
    choice=$(menu | rofi rofi -dmenu -i -config $rofi_theme)

    if [[ -z "$choice" ]]; then
        exit 0
    fi
    add_theme_to_config "$choice"
    notify-send -i "$iDIR/ja.png" -u low 'Rofi Theme applied:' "$choice"
}

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

main
