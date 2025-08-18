#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Rofi Beats to play online Music or Locally saved media files

# Variables
mDIR="$HOME/Music/"
iDIR="$HOME/.config/swaync/icons"
rofi_theme="$HOME/.config/rofi/config-rofi-Beats.rasi"
rofi_theme_1="$HOME/.config/rofi/config-rofi-Beats-menu.rasi"

# Online Stations. Edit as required
declare -A online_music=(
  ["FM - Easy Rock 96.3 📻🎶"]="https://radio-stations-philippines.com/easy-rock"
  ["FM - Easy Rock - Baguio 91.9 📻🎶"]="https://radio-stations-philippines.com/easy-rock-baguio" 
  ["FM - Love Radio 90.7 📻🎶"]="https://radio-stations-philippines.com/love"
  ["FM - WRock - CEBU 96.3 📻🎶"]="https://onlineradio.ph/126-96-3-wrock.html"
  ["FM - Fresh Philippines 📻🎶"]="https://onlineradio.ph/553-fresh-fm.html"
  ["Radio - Lofi Girl 🎧🎶"]="https://play.streamafrica.net/lofiradio"
  ["Radio - Chillhop 🎧🎶"]="http://stream.zeno.fm/fyn8eh3h5f8uv"
  ["Radio - Ibiza Global 🎧🎶"]="https://filtermusic.net/ibiza-global"
  ["Radio - Metal Music 🎧🎶"]="https://tunein.com/radio/mETaLmuSicRaDio-s119867/"
  ["YT - Wish 107.5 YT Pinoy HipHop 📻🎶"]="https://youtube.com/playlist?list=PLkrzfEDjeYJnmgMYwCKid4XIFqUKBVWEs&si=vahW_noh4UDJ5d37"
  ["YT - Youtube Top 100 Songs Global 📹🎶"]="https://youtube.com/playlist?list=PL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i&si=5jsyfqcoUXBCSLeu"
  ["YT - Wish 107.5 YT Wishclusives 📹🎶"]="https://youtube.com/playlist?list=PLkrzfEDjeYJn5B22H9HOWP3Kxxs-DkPSM&si=d_Ld2OKhGvpH48WO"
  ["YT - Relaxing Piano Music 🎹🎶"]="https://youtu.be/6H7hXzjFoVU?si=nZTPREC9lnK1JJUG"
  ["YT - Youtube Remix 📹🎶"]="https://youtube.com/playlist?list=PLeqTkIUlrZXlSNn3tcXAa-zbo95j0iN-0"
  ["YT - Korean Drama OST 📹🎶"]="https://youtube.com/playlist?list=PLUge_o9AIFp4HuA-A3e3ZqENh63LuRRlQ"
  ["YT - lofi hip hop radio beats 📹🎶"]="https://www.youtube.com/live/jfKfPfyJRdk?si=PnJIA9ErQIAw6-qd"
  ["YT - Relaxing Piano Jazz Music 🎹🎶"]="https://youtu.be/85UEqRat6E4?si=jXQL1Yp2VP_G6NSn"
)

# Populate local_music array with files from music directory and subdirectories
populate_local_music() {
  local_music=()
  filenames=()
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find -L "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
}

# Function for displaying notifications
notification() {
  notify-send -u normal -i "$iDIR/music.png" "Now Playing:" "$@"
}

# Main function for playing local music
play_local_music() {
  populate_local_music

  # Prompt the user to select a song
  choice=$(printf "%s\n" "${filenames[@]}" | rofi -i -dmenu -config $rofi_theme)

  if [ -z "$choice" ]; then
    exit 1
  fi

  # Find the corresponding file path based on user's choice and set that to play the song then continue on the list
  for (( i=0; i<"${#filenames[@]}"; ++i )); do
    if [ "${filenames[$i]}" = "$choice" ]; then

      if music_playing; then
        stop_music
      fi
	    notification "$choice"
      mpv --playlist-start="$i" --loop-playlist --vid=no  "${local_music[@]}"

      break
    fi
  done
}

# Main function for shuffling local music
shuffle_local_music() {
  if music_playing; then
    stop_music
  fi
  notification "Shuffle Play local music"

  # Play music in $mDIR on shuffle
  mpv --shuffle --loop-playlist --vid=no "$mDIR"
}

# Main function for playing online music
play_online_music() {
  choice=$(for online in "${!online_music[@]}"; do
      echo "$online"
    done | sort | rofi -i -dmenu -config "$rofi_theme")

  if [ -z "$choice" ]; then
    exit 1
  fi

  link="${online_music[$choice]}"

  if music_playing; then
    stop_music
  fi
  notification "$choice"
  
  # Play the selected online music using mpv
  mpv --shuffle --vid=no "$link"
}

# Function to check if music is already playing
music_playing() {
  pgrep -x "mpv" > /dev/null
}

# Function to stop music and kill mpv processes
stop_music() {
  mpv_pids=$(pgrep -x mpv)

  if [ -n "$mpv_pids" ]; then
    # Get the PID of the mpv process used by mpvpaper (using the unique argument added)
    mpvpaper_pid=$(ps aux | grep -- 'unique-wallpaper-process' | grep -v 'grep' | awk '{print $2}')

    for pid in $mpv_pids; do
      if ! echo "$mpvpaper_pid" | grep -q "$pid"; then
        kill -9 $pid || true 
      fi
    done
    notify-send -u low -i "$iDIR/music.png" "Music stopped" || true
  fi
}

user_choice=$(printf "%s\n" \
  "Play from Online Stations" \
  "Play from Music directory" \
  "Shuffle Play from Music directory" \
  "Stop RofiBeats" \
  | rofi -dmenu -config $rofi_theme_1)

echo "User choice: $user_choice"

case "$user_choice" in
  "Play from Online Stations")
    play_online_music
    ;;
  "Play from Music directory")
    play_local_music
    ;;
  "Shuffle Play from Music directory")
    shuffle_local_music
    ;;
  "Stop RofiBeats")
    if music_playing; then
      stop_music
    fi
    ;;
  *)
    ;;
esac
