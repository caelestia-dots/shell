#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# A modified version of Rofi-Theme-Selector, concentrating only on ~/.local and also, applying only 10 @themes in ~/.config/rofi/config.rasi
# as opposed to continous adding of //@theme

# This code is released in public domain by Dave Davenport <qball@gmpclient.org>

iDIR="$HOME/.config/swaync/images"


OS="linux"

ROFI=$(command -v rofi)
SED=$(command -v sed)
MKTEMP=$(command -v mktemp)
NOTIFY_SEND=$(command -v notify-send)

if [ -z "${SED}" ]
then
    echo "Did not find 'sed', script cannot continue."
    exit 1
fi
if [ -z "${MKTEMP}" ]
then
    echo "Did not find 'mktemp', script cannot continue."
    exit 1
fi
if [ -z "${ROFI}" ]
then
    echo "Did not find rofi, there is no point to continue."
    exit 1
fi
if [ -z "${NOTIFY_SEND}" ]
then
    echo "Did not find 'notify-send', notifications won't work."
fi

TMP_CONFIG_FILE=$(${MKTEMP}).rasi
#rofi_theme_dir="${HOME}/.local/share/rofi/themes"
rofi_config_file="${XDG_CONFIG_HOME:-${HOME}/.config}/rofi/config.rasi"

##
# Array with parts to the found themes.
# And array with the printable name.
##
declare -a themes
declare -a theme_names

##
# Function that tries to find all installed rofi themes.
# This fills in #themes array and formats a displayable string #theme_names
##
# Find themes in defined directories
find_themes() {
    directories=("$HOME/.local/share/rofi/themes" "$HOME/.config/rofi/themes")
    
    for TD in "${directories[@]}"; do
        if [ -d "$TD" ]; then
            echo "Checking themes in: $TD"
            for file in "$TD"/*.rasi; do
                if [ -f "$file" ] && [ ! -L "$file" ]; then
                    themes+=("$file")
                    theme_names+=("$(basename "${file%.*}")")
                else
                    echo "Skipping symlink: $file"
                fi
            done
        else
            echo "Directory does not exist: $TD"
        fi
    done
}

##
# Function to add or update theme in the config.rasi
##
add_theme_to_config() {
    local theme_name="$1"
    local theme_path

    # Determine the correct path for the theme
    if [[ -f "$HOME/.local/share/rofi/themes/$theme_name.rasi" ]]; then
        theme_path="$HOME/.local/share/rofi/themes/$theme_name.rasi"
    elif [[ -f "$HOME/.config/rofi/themes/$theme_name.rasi" ]]; then
        theme_path="$HOME/.config/rofi/themes/$theme_name.rasi"
    else
        echo "Theme not found: $theme_name"
        return 1
    fi

    # Resolve symlinks if present
    if [[ -L "$theme_path" ]]; then
        theme_path=$(readlink -f "$theme_path")
    fi

    # Convert path to use ~ for home directory
    theme_path_with_tilde="~${theme_path#$HOME}"

    # Add or update @theme line in config
    if ! grep -q '^\s*@theme' "$rofi_config_file"; then
        echo -e "\n\n@theme \"$theme_path_with_tilde\"" >> "$rofi_config_file"
        echo "Added @theme \"$theme_path_with_tilde\" to $rofi_config_file"
    else
        $SED -i "s/^\(\s*@theme.*\)/\/\/\1/" "$rofi_config_file"
        echo -e "@theme \"$theme_path_with_tilde\"" >> "$rofi_config_file"
        echo "Updated @theme line to $theme_path_with_tilde"
    fi

    # Limit the number of @theme lines to a maximum of 9
    max_lines=9
    total_lines=$(grep -c '^\s*//@theme' "$rofi_config_file")

    if [ "$total_lines" -gt "$max_lines" ]; then
        excess=$((total_lines - max_lines))
        for i in $(seq 1 "$excess"); do
            $SED -i '0,/^\s*\/\/@theme/ { /^\s*\/\/@theme/ {d; q; }}' "$rofi_config_file"
        done
        echo "Removed excess //@theme lines"
    fi
}

##
# Create a copy of rofi config
##
create_config_copy()
{
    ${ROFI} -dump-config > "${TMP_CONFIG_FILE}"
    # remove theme entry.
    ${SED} -i 's/^\s*theme:\s\+".*"\s*;//g' "${TMP_CONFIG_FILE}"
}

###
# Print the list out so it can be displayed by rofi.
##
create_theme_list()
{
    OLDIFS=${IFS}
    IFS='|'
    for themen in ${theme_names[@]}
    do
        echo "${themen}"
    done
    IFS=${OLDIFS}
}

##
# Thee indicate what entry is selected.
##
declare -i SELECTED

select_theme()
{
    local MORE_FLAGS=(-dmenu -format i -no-custom -p "Theme" -markup -config "${TMP_CONFIG_FILE}" -i)
    MORE_FLAGS+=(-kb-custom-1 "Alt-a")
    MORE_FLAGS+=(-u 2,3 -a 4,5 )
    local CUR="default"
    while true
    do
        declare -i RTR
        declare -i RES
        local MESG="""You can preview themes by hitting <b>Enter</b>.
<b>Alt-a</b> to accept the new theme.
<b>Escape</b> to cancel
Current theme: <b>${CUR}</b>
<span weight=\"bold\" size=\"xx-small\">When setting a new theme this will override previous theme settings.
Please update your config file if you have local modifications.</span>"""
        THEME_FLAG=
        if [ -n "${SELECTED}" ]
        then
            THEME_FLAG="-theme ${themes[${SELECTED}]}"
        fi
        RES=$( create_theme_list | ${ROFI} ${THEME_FLAG} ${MORE_FLAGS[@]} -cycle -selected-row "${SELECTED}" -mesg "${MESG}")
        RTR=$?
        if [ "${RTR}" = 10 ]
        then
            return 0;
        elif [ "${RTR}" = 1 ]
        then
            return 1;
        elif [ "${RTR}" = 65 ]
        then
            return 1;
        fi
        CUR=${theme_names[${RES}]}
        SELECTED=${RES}
    done
}

############################################################################################################
# Actual program execution
###########################################################################################################
##
# Find all themes
##
find_themes

##
# Do check if there are themes.
##
if [ ${#themes[@]} = 0 ]
then
    ${ROFI} -e "No themes found."
    exit 0
fi

##
# Create copy of config to play with in preview
##
create_config_copy

##
# Show the themes to user.
##
if select_theme && [ -n "${SELECTED}" ]
then
    # Apply the selected theme
    add_theme_to_config "${theme_names[${SELECTED}]}"

    # Send notification with the selected theme name
    selection="${theme_names[${SELECTED}]}"
    if [ -n "$NOTIFY_SEND" ]; then
        notify-send -u low -i "$iDIR/ja.png"  "Rofi Theme applied:" "$selection"
    fi
fi

##
# Remove temp. config.
##
rm -- "${TMP_CONFIG_FILE}"
