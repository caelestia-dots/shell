#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Dark and Light switching
# Note: Scripts are looking for keywords Light or Dark except for wallpapers as the are in a separate directories

# Paths
wallpaper_base_path="$HOME/Pictures/wallpapers/Dynamic-Wallpapers"
dark_wallpapers="$wallpaper_base_path/Dark"
light_wallpapers="$wallpaper_base_path/Light"
hypr_config_path="$HOME/.config/hypr"
swaync_style="$HOME/.config/swaync/style.css"
ags_style="$HOME/.config/ags/user/style.css"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
notif="$HOME/.config/swaync/images/bell.png"
wallust_rofi="$HOME/.config/wallust/templates/colors-rofi.rasi"

kitty_conf="$HOME/.config/kitty/kitty.conf"

wallust_config="$HOME/.config/wallust/wallust.toml"
pallete_dark="dark16"
pallete_light="light16"

# intial kill process
for pid in waybar rofi swaync ags swaybg; do
    killall -SIGUSR1 "$pid"
done


# Initialize swww if needed
swww query || swww-daemon --format xrgb

# Set swww options
swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 60 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Determine current theme mode
if [ "$(cat $HOME/.cache/.theme_mode)" = "Light" ]; then
    next_mode="Dark"
    # Logic for Dark mode
    wallpaper_path="$dark_wallpapers"
else
    next_mode="Light"
    # Logic for Light mode
    wallpaper_path="$light_wallpapers"
fi

# Function to update theme mode for the next cycle
update_theme_mode() {
    echo "$next_mode" > "$HOME/.cache/.theme_mode"
}

# Function to notify user
notify_user() {
    notify-send -u low -i "$notif" " Switching to" " $1 mode"
}

# Use sed to replace the palette setting in the wallust config file
if [ "$next_mode" = "Dark" ]; then
    sed -i 's/^palette = .*/palette = "'"$pallete_dark"'"/' "$wallust_config" 
else
    sed -i 's/^palette = .*/palette = "'"$pallete_light"'"/' "$wallust_config" 
fi

# Function to set Waybar style
set_waybar_style() {
    theme="$1"
    waybar_styles="$HOME/.config/waybar/style"
    waybar_style_link="$HOME/.config/waybar/style.css"
    style_prefix="\\[${theme}\\].*\\.css$"

    style_file=$(find -L "$waybar_styles" -maxdepth 1 -type f -regex ".*$style_prefix" | shuf -n 1)

    if [ -n "$style_file" ]; then
        ln -sf "$style_file" "$waybar_style_link"
    else
        echo "Style file not found for $theme theme."
    fi
}

# Call the function after determining the mode
set_waybar_style "$next_mode"
notify_user "$next_mode"


# swaync color change
if [ "$next_mode" = "Dark" ]; then
    sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.8);/' "${swaync_style}"
	#sed -i '/@define-color noti-bg-alt/s/#.*;/#111111;/' "${swaync_style}"
else
    sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.9);/' "${swaync_style}"
	#sed -i '/@define-color noti-bg-alt/s/#.*;/#F0F0F0;/' "${swaync_style}"
fi

# ags color change
if command -v ags >/dev/null 2>&1; then    
    if [ "$next_mode" = "Dark" ]; then
        sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.4);/' "${ags_style}"
	    sed -i '/@define-color text-color/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.7);/' "${ags_style}" 
	    sed -i '/@define-color noti-bg-alt/s/#.*;/#111111;/' "${ags_style}"
    else
        sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.4);/' "${ags_style}"
        sed -i '/@define-color text-color/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.7);/' "${ags_style}"
	    sed -i '/@define-color noti-bg-alt/s/#.*;/#F0F0F0;/' "${ags_style}"
    fi
fi

# kitty background color change
if [ "$next_mode" = "Dark" ]; then
    sed -i '/^foreground /s/^foreground .*/foreground #dddddd/' "${kitty_conf}"
	sed -i '/^background /s/^background .*/background #000000/' "${kitty_conf}"
	sed -i '/^cursor /s/^cursor .*/cursor #dddddd/' "${kitty_conf}"
else
	sed -i '/^foreground /s/^foreground .*/foreground #000000/' "${kitty_conf}"
	sed -i '/^background /s/^background .*/background #dddddd/' "${kitty_conf}"
	sed -i '/^cursor /s/^cursor .*/cursor #000000/' "${kitty_conf}"
fi

for pid_kitty in $(pidof kitty); do
    kill -SIGUSR1 "$pid_kitty"
done

# Set Dynamic Wallpaper for Dark or Light Mode
if [ "$next_mode" = "Dark" ]; then
    next_wallpaper="$(find -L "${dark_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
else
    next_wallpaper="$(find -L "${light_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
fi

# Update wallpaper using swww command
$swww "${next_wallpaper}" $effect


# Set Kvantum Manager theme & QT5/QT6 settings
if [ "$next_mode" = "Dark" ]; then
    kvantum_theme="catppuccin-mocha-blue"
    #qt5ct_color_scheme="$HOME/.config/qt5ct/colors/Catppuccin-Mocha.conf"
    #qt6ct_color_scheme="$HOME/.config/qt6ct/colors/Catppuccin-Mocha.conf"
else
    kvantum_theme="catppuccin-latte-blue"
    #qt5ct_color_scheme="$HOME/.config/qt5ct/colors/Catppuccin-Latte.conf"
    #qt6ct_color_scheme="$HOME/.config/qt6ct/colors/Catppuccin-Latte.conf"
fi

sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt5ct_color_scheme|" "$HOME/.config/qt5ct/qt5ct.conf"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt6ct_color_scheme|" "$HOME/.config/qt6ct/qt6ct.conf"
kvantummanager --set "$kvantum_theme"


# set the rofi color for background
if [ "$next_mode" = "Dark" ]; then
    sed -i '/^background:/s/.*/background: rgba(0,0,0,0.7);/' $wallust_rofi
else
    sed -i '/^background:/s/.*/background: rgba(255,255,255,0.9);/' $wallust_rofi
fi


# GTK themes and icons switching
set_custom_gtk_theme() {
    mode=$1
    gtk_themes_directory="$HOME/.themes"
    icon_directory="$HOME/.icons"
    color_setting="org.gnome.desktop.interface color-scheme"
    theme_setting="org.gnome.desktop.interface gtk-theme"
    icon_setting="org.gnome.desktop.interface icon-theme"

    if [ "$mode" == "Light" ]; then
        search_keywords="*Light*"
        gsettings set $color_setting 'prefer-light'
    elif [ "$mode" == "Dark" ]; then
        search_keywords="*Dark*"
        gsettings set $color_setting 'prefer-dark'
    else
        echo "Invalid mode provided."
        return 1
    fi

    themes=()
    icons=()

    while IFS= read -r -d '' theme_search; do
        themes+=("$(basename "$theme_search")")
    done < <(find "$gtk_themes_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

    while IFS= read -r -d '' icon_search; do
        icons+=("$(basename "$icon_search")")
    done < <(find "$icon_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

    if [ ${#themes[@]} -gt 0 ]; then
        if [ "$mode" == "Dark" ]; then
            selected_theme=${themes[RANDOM % ${#themes[@]}]}
        else
            selected_theme=${themes[$RANDOM % ${#themes[@]}]}
        fi
        echo "Selected GTK theme for $mode mode: $selected_theme"
        gsettings set $theme_setting "$selected_theme"

        # Flatpak GTK apps (themes)
        if command -v flatpak &> /dev/null; then
            flatpak --user override --filesystem=$HOME/.themes
            sleep 0.5
            flatpak --user override --env=GTK_THEME="$selected_theme"
        fi
    else
        echo "No $mode GTK theme found"
    fi

    if [ ${#icons[@]} -gt 0 ]; then
        if [ "$mode" == "Dark" ]; then
            selected_icon=${icons[RANDOM % ${#icons[@]}]}
        else
            selected_icon=${icons[$RANDOM % ${#icons[@]}]}
        fi
        echo "Selected icon theme for $mode mode: $selected_icon"
        gsettings set $icon_setting "$selected_icon"
        
        ## QT5ct icon_theme
        sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt5ct/qt5ct.conf"
        sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt6ct/qt6ct.conf"

        # Flatpak GTK apps (icons)
        if command -v flatpak &> /dev/null; then
            flatpak --user override --filesystem=$HOME/.icons
            sleep 0.5
            flatpak --user override --env=ICON_THEME="$selected_icon"
        fi
    else
        echo "No $mode icon theme found"
    fi
}

# Call the function to set GTK theme and icon theme based on mode
set_custom_gtk_theme "$next_mode"

# Update theme mode for the next cycle
update_theme_mode


${SCRIPTSDIR}/WallustSwww.sh &&

sleep 2
# kill process
for pid1 in waybar rofi swaync ags swaybg; do
    killall "$pid1"
done

sleep 1
${SCRIPTSDIR}/Refresh.sh 

sleep 0.5
# Display notifications for theme and icon changes 
notify-send -u low -i "$notif" " Themes switched to:" " $next_mode Mode"

exit 0

