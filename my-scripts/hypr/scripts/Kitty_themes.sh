#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Kitty Themes Source https://github.com/dexpota/kitty-themes #

# Define directories and variables
kitty_themes_DiR="$HOME/.config/kitty/kitty-themes" # Kitty Themes Directory
kitty_config="$HOME/.config/kitty/kitty.conf"
iDIR="$HOME/.config/swaync/images" # For notifications
rofi_theme_for_this_script="$HOME/.config/rofi/config-kitty-theme.rasi"

# --- Helper Functions ---
notify_user() {
  notify-send -u low -i "$1" "$2" "$3"
}

# Function to apply the selected kitty theme
apply_kitty_theme_to_config() {
  local theme_name_to_apply="$1"
  if [ -z "$theme_name_to_apply" ]; then
    echo "Error: No theme name provided to apply_kitty_theme_to_config." >&2
    return 1
  fi

  local theme_file_path_to_apply="$kitty_themes_DiR/$theme_name_to_apply.conf"
  if [ ! -f "$theme_file_path_to_apply" ]; then
    notify_user "$iDIR/error.png" "Error" "Theme file not found: $theme_name_to_apply.conf"
    return 1
  fi

  local temp_kitty_config_file
  temp_kitty_config_file=$(mktemp)
  cp "$kitty_config" "$temp_kitty_config_file"

  if grep -q -E '^[#[:space:]]*include\s+\./kitty-themes/.*\.conf' "$temp_kitty_config_file"; then
    sed -i -E "s|^([#[:space:]]*include\s+\./kitty-themes/).*\.conf|include ./kitty-themes/$theme_name_to_apply.conf|g" "$temp_kitty_config_file"
  else
    if [ -s "$temp_kitty_config_file" ] && [ "$(tail -c1 "$temp_kitty_config_file")" != "" ]; then
      echo >>"$temp_kitty_config_file"
    fi
    echo "include ./kitty-themes/$theme_name_to_apply.conf" >>"$temp_kitty_config_file"
  fi

  cp "$temp_kitty_config_file" "$kitty_config"
  rm "$temp_kitty_config_file"

  for pid_kitty in $(pidof kitty); do
    if [ -n "$pid_kitty" ]; then
      kill -SIGUSR1 "$pid_kitty"
    fi
  done
  return 0
}

# --- Main Script Execution ---

if [ ! -d "$kitty_themes_DiR" ]; then
  notify_user "$iDIR/error.png" "E-R-R-O-R" "Kitty Themes directory not found: $kitty_themes_DiR"
  exit 1
fi

if [ ! -f "$rofi_theme_for_this_script" ]; then
  notify_user "$iDIR/error.png" "Rofi Config Missing" "Rofi theme for Kitty selector not found at: $rofi_theme_for_this_script."
  exit 1
fi

original_kitty_config_content_backup=$(cat "$kitty_config")

mapfile -t available_theme_names < <(find "$kitty_themes_DiR" -maxdepth 1 -name "*.conf" -type f -printf "%f\n" | sed 's/\.conf$//' | sort)

if [ ${#available_theme_names[@]} -eq 0 ]; then
  notify_user "$iDIR/error.png" "No Kitty Themes" "No .conf files found in $kitty_themes_DiR."
  exit 1
fi

current_selection_index=0
current_active_theme_name=$(awk -F'include ./kitty-themes/|\\.conf' '/^[[:space:]]*include \.\/kitty-themes\/.*\.conf/{print $2; exit}' "$kitty_config")

if [ -n "$current_active_theme_name" ]; then
  for i in "${!available_theme_names[@]}"; do
    if [[ "${available_theme_names[$i]}" == "$current_active_theme_name" ]]; then
      current_selection_index=$i
      break
    fi
  done
fi

while true; do
  theme_to_preview_now="${available_theme_names[$current_selection_index]}"

  if ! apply_kitty_theme_to_config "$theme_to_preview_now"; then
    echo "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    notify_user "$iDIR/error.png" "Preview Error" "Failed to apply $theme_to_preview_now. Reverted."
    exit 1
  fi

  rofi_input_list=""
  for theme_name_in_list in "${available_theme_names[@]}"; do
    rofi_input_list+="$theme_name_in_list\n"
  done
  rofi_input_list_trimmed="${rofi_input_list%\\n}"

  chosen_index_from_rofi=$(echo -e "$rofi_input_list_trimmed" |
    rofi -dmenu -i \
      -format 'i' \
      -p "Kitty Theme" \
      -mesg "Preview: ${theme_to_preview_now} | Enter: Preview | Ctrl+S: Apply & Exit | Esc: Cancel" \
      -config "$rofi_theme_for_this_script" \
      -selected-row "$current_selection_index" \
      -kb-custom-1 "Control+s") # MODIFIED HERE: Changed to Control+s for custom action 1

  rofi_exit_code=$?

  if [ $rofi_exit_code -eq 0 ]; then
    if [[ "$chosen_index_from_rofi" =~ ^[0-9]+$ ]] && [ "$chosen_index_from_rofi" -lt "${#available_theme_names[@]}" ]; then
      current_selection_index="$chosen_index_from_rofi"
    else
      :
    fi
  elif [ $rofi_exit_code -eq 1 ]; then
    notify_user "$iDIR/note.png" "Kitty Theme" "Selection cancelled. Reverting to original theme."
    echo "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  elif [ $rofi_exit_code -eq 10 ]; then # This is the exit code for -kb-custom-1
    notify_user "$iDIR/ja.png" "Kitty Theme Applied" "$theme_to_preview_now"
    break
  else
    notify_user "$iDIR/error.png" "Rofi Error" "Unexpected Rofi exit ($rofi_exit_code). Reverting."
    echo "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  fi
done

exit 0
