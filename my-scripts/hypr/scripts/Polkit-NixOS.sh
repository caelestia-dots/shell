#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For NixOS starting of polkit-gnome. Dec 2023, the settings stated in NixOS wiki does not work so have to manual start it

# Find all polkit-gnome executables in the Nix store
polkit_gnome_paths=$(find /nix/store -name 'polkit-gnome-authentication-agent-1' -type f 2>/dev/null)

for polkit_gnome_path in $polkit_gnome_paths; do
  # Extract the directory containing the executable
  polkit_gnome_dir=$(dirname "$polkit_gnome_path")

  # Check if the executable is valid and exists
  if [ -x "$polkit_gnome_dir/polkit-gnome-authentication-agent-1" ]; then
    # Start the Polkit-GNOME Authentication Agent
    "$polkit_gnome_dir/polkit-gnome-authentication-agent-1" &
    exit 0
  fi
done

# If no valid executable is found, report an error
echo "No valid Polkit-GNOME Authentication Agent executable found."