#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# simple bash script to check if update is available by comparing local version and github version

# Local Paths
local_dir="$HOME/.config/hypr"
iDIR="$HOME/.config/swaync/images/"
local_version=$(ls $local_dir/v* 2>/dev/null | sort -V | tail -n 1 | sed 's/.*v\(.*\)/\1/')
KooL_Dots_DIR="$HOME/Hyprland-Dots"

# exit if cannot find local version
if [ -z "$local_version" ]; then
  notify-send -i "$iDIR/error.png" "ERROR "!?!?!!"" "Unable to find KooL's dots version . exiting.... "
  exit 1
fi

# GitHub URL - KooL's dots
branch="main"
github_url="https://github.com/JaKooLit/Hyprland-Dots/tree/$branch/config/hypr/"

# Fetch the version from GitHub URL - KooL's dots
github_version=$(curl -s $github_url | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -n 1 | sed 's/v//')

# Cant find  GitHub URL - KooL's dots version
if [ -z "$github_version" ]; then
  exit 1
fi

# Comparing local and github versions
if [ "$(echo -e "$github_version\n$local_version" | sort -V | head -n 1)" = "$github_version" ]; then
   notify-send -i "$iDIR/note.png" "KooL Hyprland:" "No update available"
  exit 0
else
  # update available
  notify_cmd_base="notify-send -t 10000 -A action1=Update -A action2=NO -h string:x-canonical-private-synchronous:shot-notify"
  notify_cmd_shot="${notify_cmd_base} -i $iDIR/ja.png"

  response=$($notify_cmd_shot "KooL Hyprland:" "Update available! Update now?")

  case "$response" in
    "action1")  
      if [ -d $KooL_Dots_DIR ]; then
      	if ! command -v kitty &> /dev/null; then
  			notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Kitty terminal not found. Please install Kitty terminal."
  			exit 1
		fi
        kitty -e bash -c "
          cd $KooL_Dots_DIR &&
          git stash &&
          git pull &&
          ./copy.sh &&
		  notify-send -u critical -i "$iDIR/ja.png" 'Update Completed:' 'Kindly log out and relogin to take effect'
        "
	
      else
         if ! command -v kitty &> /dev/null; then
  		  	notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Kitty terminal not found. Please install Kitty terminal."
  			exit 1
		fi
        kitty -e bash -c "
          git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git $KooL_Dots_DIR &&
          cd $KooL_Dots_DIR &&
          chmod +x copy.sh &&
          ./copy.sh &&
		  notify-send -u critical -i "$iDIR/ja.png" 'Update Completed:' 'Kindly log out and relogin to take effect'
        "
      fi
      ;;
    "action2")
      exit 0
      ;;
  esac
fi
