#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Oh my ZSH theme ( CTRL SHIFT O)

# preview of theme can be view here: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# after choosing theme, TTY need to be closed and re-open

# Variables
iDIR="$HOME/.config/swaync/images"
rofi_theme="$HOME/.config/rofi/config-zsh-theme.rasi"

if [ -n "$(grep -i nixos < /etc/os-release)" ]; then
  notify-send -i "$iDIR/note.png" "NOT Supported" "Sorry NixOS does not support this KooL feature"
  exit 1
fi

themes_dir="$HOME/.oh-my-zsh/themes"
file_extension=".zsh-theme"


themes_array=($(find -L "$themes_dir" -type f -name "*$file_extension" -exec basename {} \; | sed -e "s/$file_extension//"))

# Add "Random" option to the beginning of the array
themes_array=("Random" "${themes_array[@]}")

rofi_command="rofi -i -dmenu -config $rofi_theme"

menu() {
    for theme in "${themes_array[@]}"; do
        echo "$theme"
    done
}

main() {
    choice=$(menu | ${rofi_command})

    # if nothing selected, script won't change anything
    if [ -z "$choice" ]; then
        exit 0
    fi

    zsh_path="$HOME/.zshrc"
    var_name="ZSH_THEME"

    if [[ "$choice" == "Random" ]]; then
        # Pick a random theme from the original themes_array (excluding "Random")
        random_theme=${themes_array[$((RANDOM % (${#themes_array[@]} - 1) + 1))]}
        theme_to_set="$random_theme"
        notify-send -i "$iDIR/ja.png" "Random theme:" "selected: $random_theme"
    else
        # Set theme to the selected choice
        theme_to_set="$choice"
        notify-send -i "$iDIR/ja.png" "Theme selected:" "$choice"
    fi

    if [ -f "$zsh_path" ]; then
        sed -i "s/^$var_name=.*/$var_name=\"$theme_to_set\"/" "$zsh_path"
        notify-send -i "$iDIR/ja.png" "OMZ theme" "applied. restart your terminal"
    else
        notify-send -i "$iDIR/error.png" "E-R-R-O-R" "~.zshrc file not found!"
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main
