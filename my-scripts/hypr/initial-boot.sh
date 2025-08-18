#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# A bash script designed to run only once dotfiles installed

# THIS SCRIPT CAN BE DELETED ONCE SUCCESSFULLY BOOTED!! And also, edit ~/.config/hypr/configs/Settings.conf
# NOT necessary to do since this script is only designed to run only once as long as the marker exists
# marker file is located at ~/.config/hypr/.initial_startup_done
# However, I do highly suggest not to touch it since again, as long as the marker exist, script wont run

# Variables
scriptsDir=$HOME/.config/hypr/scripts
wallpaper=$HOME/.config/hypr/wallpaper_effects/.wallpaper_current
waybar_style="$HOME/.config/waybar/style/[Extra] Modern-Combined - Transparent.css"
kvantum_theme="catppuccin-mocha-blue"
color_scheme="prefer-dark"
gtk_theme="Flat-Remix-GTK-Blue-Dark"
icon_theme="Flat-Remix-Blue-Dark"
cursor_theme="Bibata-Modern-Ice"

swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 30 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Check if a marker file exists.
if [ ! -f "$HOME/.config/hypr/.initial_startup_done" ]; then
    sleep 1
    # Initialize wallust and wallpaper
	if [ -f "$wallpaper" ]; then
		wallust run -s $wallpaper > /dev/null 
		swww query || swww-daemon && $swww $wallpaper $effect
	    "$scriptsDir/WallustSwww.sh" > /dev/null 2>&1 & 
	fi
     
    # initiate GTK dark mode and apply icon and cursor theme
    gsettings set org.gnome.desktop.interface color-scheme $color_scheme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface gtk-theme $gtk_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme $icon_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-theme $cursor_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &

     # NIXOS initiate GTK dark mode and apply icon and cursor theme
	if [ -n "$(grep -i nixos < /etc/os-release)" ]; then
      gsettings set org.gnome.desktop.interface color-scheme "'$color_scheme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/icon-theme "'$icon_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/cursor-theme "'$cursor_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/cursor-size "24" > /dev/null 2>&1 &
	fi
       
    # initiate kvantum theme
    kvantummanager --set "$kvantum_theme" > /dev/null 2>&1 &

    # initiate the kb_layout (for some reason) waybar cant launch it
    "$scriptsDir/SwitchKeyboardLayout.sh" > /dev/null 2>&1 &

	# waybar style
	#if [ -L "$HOME/.config/waybar/config" ]; then
    ##    	ln -sf "$waybar_style" "$HOME/.config/waybar/style.css"
    #   	"$scriptsDir/Refresh.sh" > /dev/null 2>&1 & 
	#fi


    # Create a marker file to indicate that the script has been executed.
    touch "$HOME/.config/hypr/.initial_startup_done"

    exit
fi
