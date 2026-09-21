# Updating a running system

1. Pull the latest code:

    ```sh
    git pull origin main
    ```

2. Install any new dependencies. Check the README's dependency list for anything new.
   At the time of writing, this includes:

    ```sh
    sudo pacman -S qt6-imageformats
    paru -S qt6-m3shapes-git ttf-rubik-vf
    ```

3. Rebuild:

    ```sh
    cmake --build build
    ```

4. Remove stale installed libraries before reinstalling, otherwise old files can shadow
   the new ones and cause "undefined symbol" errors:

    ```sh
    sudo rm -rf /usr/lib/qt6/qml/Caelestia /usr/lib/caelestia
    ```

5. Reinstall:

    ```sh
    sudo cmake --install build
    ```

6. Restart the shell and check the logs if anything looks wrong:

    ```sh
    caelestia shell -d
    ```

    Logs are at `/run/user/$UID/quickshell/by-id/*/log.qslog`.
