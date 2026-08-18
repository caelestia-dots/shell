<h1 align=center>caelestia-shell</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=d3bfe6)
[![Ko-Fi donate](https://img.shields.io/badge/donate-kofi?style=for-the-badge&logo=ko-fi&logoColor=ffffff&label=ko-fi&labelColor=101418&color=f16061&link=https%3A%2F%2Fko-fi.com%2Fsoramane)](https://ko-fi.com/soramane)
[![Discord invite](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FBGDCFCmMBk%3Fwith_counts%3Dtrue&query=approximate_member_count&style=for-the-badge&logo=discord&logoColor=ffffff&label=discord&labelColor=101418&color=96f1f1&link=https%3A%2F%2Fdiscord.gg%2FBGDCFCmMBk)][discord]

</div>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

## Components

-   Widgets: [`Quickshell`](https://quickshell.outfoxxed.me)
-   Window manager: [`Hyprland`](https://hypr.land)
-   Dots: [`caelestia`][dots-repo]

## Installation

> [!NOTE]
> This repo is for Caelestia's desktop shell only. If you want installation instructions
> for the entire dotfiles (which include this shell), head to [the main repo][dots-repo] instead.

### Arch Linux

> [!WARNING]
> If you want to make your own changes/tweaks to the shell, do NOT edit the files installed by the AUR
> package. Instead, follow the instructions in the [manual installation section](#manual-installation).

The shell is available from the AUR as `caelestia-shell`. You can install it with an AUR helper (recommended),
like [`paru`](https://github.com/morganamilo/paru), or by manually downloading the PKGBUILD and running `makepkg -si`.

A package following the latest commit also exists as `caelestia-shell-git`. This is bleeding-edge
and likely to be unstable/have bugs. Regular users are recommended to use the stable package (`caelestia-shell`).

### Nix

You can run the shell directly via `nix run`:

```sh
nix run github:caelestia-dots/shell#with-cli
```

Or add it to your system configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

For full functionality, use `caelestia-shell.packages.<system>.with-cli`, which can be added to your
`environment.systemPackages`, `users.users.<username>.packages`, `home.packages` if using home-manager,
or a devshell. The `default` package does not include the CLI.
You can then run the shell with `caelestia-shell`.

For home-manager, you can also use Caelestia's Home Manager module (explained in [the configuration section](#home-manager-module)), which installs and configures the shell and CLI.

### Manual installation

Dependencies:

-   [`caelestia-cli`](https://github.com/caelestia-dots/cli)
-   [`quickshell-git`](https://git.outfoxxed.me/quickshell/quickshell) - this has to be the git version, not the latest tagged version
-   `glibc`
-   `gcc-libs`
-   [`ddcutil`](https://github.com/rockowitz/ddcutil)
-   [`brightnessctl`](https://github.com/Hummer12007/brightnessctl)
-   [`libcava`](https://github.com/LukashonakV/cava)
-   [`networkmanager`](https://gitlab.freedesktop.org/NetworkManager/NetworkManager)
-   [`lm_sensors`](https://github.com/lm-sensors/lm-sensors)
-   [`aubio`](https://github.com/aubio/aubio)
-   [`libpipewire`](https://github.com/PipeWire/pipewire)
-   [`libqalculate`](https://github.com/Qalculate/libqalculate)
-   [`power-profiles-daemon`](https://gitlab.freedesktop.org/upower/power-profiles-daemon)
-   [`ttf-material-symbols-variable`](https://github.com/google/material-design-icons)
-   [`ttf-rubik-vf`](https://github.com/googlefonts/rubik)
-   [`ttf-cascadia-code-nerd`](https://github.com/ryanoasis/nerd-fonts)
-   `qt6-base`
-   `qt6-declarative`
-   `qt6-imageformats`
-   [`swappy`](https://github.com/jtheoof/swappy)
-   [`fish`](https://github.com/fish-shell/fish-shell)
-   [`bash`](https://www.gnu.org/software/bash)

Build dependencies:

-   [`cmake`](https://gitlab.kitware.com/cmake/cmake)
-   [`ninja`](https://github.com/ninja-build/ninja)
-   `qt6-shadertools`

> [!IMPORTANT]
> The commands (and in the "Updating" section) expect `$XDG_CONFIG_HOME` to be set.
> If it is unset, substitute it with the path to your config folder (typically `~/.config`).

To install the shell manually, install all dependencies and clone this repo to `$XDG_CONFIG_HOME/quickshell/caelestia`.
Then build and install using `cmake`.

```sh
cd $XDG_CONFIG_HOME/quickshell
git clone https://github.com/caelestia-dots/shell.git caelestia

cd caelestia
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

> [!TIP]
> You can customise the installation location via the CMake flags `INSTALL_LIBDIR`, `INSTALL_QMLDIR`, and
> `INSTALL_QSCONFDIR` for the libraries (e.g., the beat detector), QML plugin, and Quickshell config directories
> respectively. If changing the library directory, remember to set the `CAELESTIA_LIB_DIR` environment
> variable to the custom directory when launching the shell.
>
> e.g., installing to `~/.config/quickshell/caelestia` for easy local changes:
>
> ```sh
> mkdir -p ~/.config/quickshell/caelestia
> cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"
> cmake --build build
> sudo cmake --install build
> sudo chown -R $USER ~/.config/quickshell/caelestia
> ```

## Usage

You can start the shell by running `caelestia shell -d` (preferred) or `qs -c caelestia -n -d`.
You may omit `-d` from the command to keep the shell attached to the current terminal if necessary,
though you likely want it to be detached (so it doesn't close when the terminal is closed).

If using the [Caelestia dotfiles][dots-repo], the shell will be autostarted on login
via a `hl.on("hyprland.start", ...)` function in the Hyprland config.

### Shortcuts/IPC

All keybinds are accessible via Hyprland [global shortcuts](https://wiki.hypr.land/Configuring/Basics/Binds/#dbus-global-shortcuts).
If using the [Caelestia dotfiles][dots-repo], the keybinds are already configured for you.
Otherwise, the [`keybinds.lua` file](https://github.com/caelestia-dots/caelestia/blob/main/hypr/hyprland/keybinds.lua#L63-L67)
contains an example of how to use global shortcuts.

All IPC commands can be accessed via `caelestia shell ...`, for example:

```sh
caelestia shell mpris getActive trackTitle
```

You can view the list of available IPC commands by running `caelestia shell -s`.

### PFP/Wallpapers

The profile picture for the dashboard is read from the file `~/.face`. You can set it by clicking it in the dashboard,
or by manually copying or symlinking your image to the path.

The wallpapers for the wallpaper switcher are read from `~/Pictures/Wallpapers`
by default. To change it, modify `paths.wallpaperDir` in `~/.config/caelestia/shell.json`.

To set the wallpaper, you can use `caelestia wallpaper -f <path_to_wallpaper>`.
Use `caelestia wallpaper -h` for more info about this command.

## Updating

### Packaged install (AUR)

If using the full dotfiles or the CLI, run `caelestia update` to perform a full system update and
update the dots.
Otherwise, if you installed the shell on its own, update your system using your AUR helper (e.g., `paru`).

### Manual install

If you installed the shell manually by cloning the repo, you can update by pulling the changes from git
in the local checkout.

For example, if you installed to `$XDG_CONFIG_HOME/quickshell/caelestia`:

```sh
cd $XDG_CONFIG_HOME/quickshell/caelestia
git pull
```

## Configuring

All configuration options belong in `~/.config/caelestia/shell.json`. This file is _not_ created by
default; you must create it manually. Options that you omit from the config file will use their default
values.

### Per-monitor configuration

You can configure per-monitor options in `~/.config/caelestia/monitors/<monitor_name>/shell.json`.
List the names of your available monitors by running:

```sh
hyprctl monitors -j | jq -r '.[].name'
```

Options set in these files will **override** the respective options in the global config. Any options not present in
per-monitor configs will inherit their values from the global config.


For example, to disable the bar on the monitor named `DP-1`:

**`~/.config/caelestia/monitors/DP-1/shell.json`**

```json
{
    "bar": {
        "persistent": false
    }
}
```

> [!NOTE]
> Not all options respect per-monitor overrides. Most notably, the following options will only read
> from the global config, and ignore the respective option in per-monitor config files.
>
> <details><summary>Ignored options</summary>
>
> - `appearance`: `anim.*`, `transparency.*`
> - `bar.tray`: `hiddenIcons`, `iconSubs`
> - `bar.workspaces`: `perMonitorWorkspaces`, `specialWorkspaceIcons`, `windowIcons`
> - `dashboard`: `mediaUpdateInterval`, `resourceUpdateInterval`
> - `general`: `apps.*`, `battery.*`, `idle.*`, `logo`
> - `launcher`: `actionPrefix`, `actions`, `enableDangerousActions`, `favouriteApps`, `hiddenApps`, `specialPrefix`, `useFuzzy.*`, `vimKeybinds`
> - `lock`: `enableFprint`, `enableHowdy`, `maxFprintTries`, `maxHowdyTries`, `triggerHowdyOnWake`
> - `nexus`: `networkRescanInterval`
> - `notifs`: `actionOnClick`, `defaultExpireTimeout`, `expire`, `fullscreen`, `fullscreenExpireTimeout`
> - `paths`: `lyricsDir`, `wallpaperDir`
> - `services`: `audioIncrement`, `brightnessIncrement`, `defaultPlayer`, `gpuType`, `lyricsBackend`, `maxVolume`, `playerAliases`, `smartScheme`, `useFahrenheit`, `useFahrenheitPerformance`, `useTwelveHourClock`, `visualiserBars`, `weatherLocation`
> - `utilities.toasts`: all except `fullscreen`
> - `utilities.vpn`: `enabled`, `provider`, `selectedProvider`
>
> </details>

### Example configuration

> [!WARNING]
> The example configuration includes **ALL** configuration options in `shell.json`. It is
> **not** recommended to copy and paste this entire configuration into `shell.json`,
> as options or their default values may be updated, resulting in a stale config.
>
> This is meant to serve as a reference of all the available options, and you should
> <ins>only add the ones you want to change</ins> to `shell.json`.

<details><summary>Example config</summary>

```json
{
    "appearance": {
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "deformScale": 1,
        "font": {
            "body": {
                "family": "GoogleSansFlex",
                "large": { "italic": false, "size": 16, "vaxes": { "ROND": 25 }, "weight": 400 },
                "medium": { "italic": false, "size": 14, "vaxes": { "ROND": 25 }, "weight": 400 },
                "small": { "italic": false, "size": 12, "vaxes": { "ROND": 25 }, "weight": 400 }
            },
            "clock": "Rubik",
            "headline": {
                "family": "GoogleSansFlex",
                "large": { "italic": false, "size": 32, "vaxes": { "ROND": 25 }, "weight": 500 },
                "medium": { "italic": false, "size": 28, "vaxes": { "ROND": 25 }, "weight": 500 },
                "small": { "italic": false, "size": 24, "vaxes": {"ROND": 25 }, "weight": 500 }
            },
            "icon": {
                "extraLarge": { "italic": false, "size": 36, "vaxes": {}, "weight": 400 },
                "family": "Material Symbols Rounded",
                "large": { "italic": false, "size": 24, "vaxes": {}, "weight": 400 },
                "medium": { "italic": false, "size": 18, "vaxes": {}, "weight": 400 },
                "small": { "italic": false, "size": 15, "vaxes": {}, "weight": 400 }
            },
            "label": {
                "family": "GoogleSansFlex",
                "large": { "italic": false, "size": 14, "vaxes": { "ROND": 25 }, "weight": 500 },
                "medium": { "italic": false, "size": 12, "vaxes": { "ROND": 25 }, "weight": 500 },
                "small": { "italic": false, "size": 11, "vaxes": { "ROND": 25 }, "weight": 400 }
            },
            "mono": {
                "family": "CaskaydiaCove NF",
                "large": { "italic": false, "size": 16, "vaxes": {}, "weight": 400 },
                "medium": { "italic": false, "size": 14, "vaxes": {}, "weight": 400 },
                "small": { "italic": false, "size": 12, "vaxes": {}, "weight": 400 }
            },
            "scale": 1,
            "title": {
                "family": "GoogleSansFlex",
                "large": { "italic": false, "size": 22, "vaxes": { "ROND": 25 }, "weight": 500 },
                "medium": { "italic": false, "size": 16, "vaxes": { "ROND": 25 }, "weight": 500 },
                "small": { "italic": false, "size": 14, "vaxes": { "ROND": 25 }, "weight": 500 }
            },
            "workspaces": "Rubik"
        },
        "padding": {
            "scale": 1
        },
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "transparency": {
            "base": 0.85,
            "enabled": false,
            "layers": 0.4
        }
    },
    "background": {
        "desktopClock": {
            "background": {
                "blur": true,
                "enabled": false,
                "opacity": 0.7
            },
            "enabled": false,
            "invertColors": false,
            "position": "bottom-right",
            "scale": 1.0,
            "shadow": {
                "blur": 0.4,
                "enabled": true,
                "opacity": 0.7
            }
        },
        "enabled": true,
        "visualiser": {
            "autoHide": true,
            "blur": false,
            "enabled": false,
            "rounding": 1,
            "spacing": 1
        },
        "wallpaperEnabled": true
    },
    "bar": {
        "activeWindow": {
            "compact": false,
            "inverted": false,
            "showOnHover": true
        },
        "clock": {
            "background": false,
            "showDate": false,
            "showIcon": true
        },
        "dragThreshold": 20,
        "entries": [
            {
                "enabled": true,
                "id": "logo"
            },
            {
                "enabled": true,
                "id": "workspaces"
            },
            {
                "enabled": true,
                "id": "spacer"
            },
            {
                "enabled": true,
                "id": "activeWindow"
            },
            {
                "enabled": true,
                "id": "spacer"
            },
            {
                "enabled": true,
                "id": "tray"
            },
            {
                "enabled": true,
                "id": "clock"
            },
            {
                "enabled": true,
                "id": "statusIcons"
            },
            {
                "enabled": true,
                "id": "power"
            }
        ],
        "excludedScreens": [],
        "persistent": true,
        "popouts": {
            "activeWindow": true,
            "statusIcons": true,
            "tray": true
        },
        "scrollActions": {
            "brightness": true,
            "volume": true,
            "workspaces": true
        },
        "showOnHover": true,
        "statusIcons": [
            {
                "enabled": true,
                "id": "lockStatus"
            },
            {
                "enabled": false,
                "id": "audio"
            },
            {
                "enabled": false,
                "id": "microphone"
            },
            {
                "enabled": false,
                "id": "kbLayout"
            },
            {
                "enabled": true,
                "id": "network"
            },
            {
                "enabled": true,
                "id": "bluetooth"
            },
            {
                "enabled": true,
                "id": "battery"
            }
        ],
        "tray": {
            "background": false,
            "compact": false,
            "hiddenIcons": [],
            "iconSubs": [],
            "recolour": false
        },
        "workspaces": {
            "activeIndicator": true,
            "activeLabel": "󰮯",
            "activeTrail": false,
            "capitalisation": "preserve",
            "label": "  ",
            "maxWindowIcons": 5,
            "occupiedBg": false,
            "occupiedLabel": "󰮯",
            "perMonitorWorkspaces": true,
            "showWindows": true,
            "showWindowsOnSpecialWorkspaces": true,
            "shown": 5,
            "specialWorkspaceIcons": [
                {
                    "icon": "sports_esports",
                    "name": "steam"
                }
            ],
            "windowIcons": [
                {
                    "icon": "sports_esports",
                    "regex": "steam(_app_(default|[0-9]+))?"
                }
            ]
        }
    },
    "border": {
        "rounding": 25,
        "smoothing": 20,
        "thickness": 10
    },
    "dashboard": {
        "dragThreshold": 50,
        "enabled": true,
        "mediaUpdateInterval": 500,
        "performance": {
            "showBattery": true,
            "showCpu": true,
            "showGpu": true,
            "showMemory": true,
            "showNetwork": true,
            "showStorage": true
        },
        "resourceUpdateInterval": 1000,
        "showDashboard": true,
        "showMedia": true,
        "showOnHover": true,
        "showPerformance": true,
        "showWeather": true
    },
    "enabled": true,
    "general": {
        "apps": {
            "audio": ["pwvucontrol"],
            "explorer": ["thunar"],
            "playback": ["mpv"],
            "terminal": ["foot"]
        },
        "battery": {
            "criticalLevel": 3,
            "warnLevels": [
                {
                    "icon": "battery_android_frame_2",
                    "level": 20,
                    "message": "You might want to plug in a charger",
                    "title": "Low battery"
                },
                {
                    "icon": "battery_android_frame_1",
                    "level": 10,
                    "message": "You should probably plug in a charger <b>now</b>",
                    "title": "Did you see the previous message?"
                },
                {
                    "critical": true,
                    "icon": "battery_android_alert",
                    "level": 5,
                    "message": "PLUG THE CHARGER RIGHT NOW!!",
                    "title": "Critical battery level"
                }
            ]
        },
        "idle": {
            "inhibitWhenAudio": true,
            "inhibitWhenCharging": false,
            "lockBeforeSleep": true,
            "timeouts": [
                {
                    "idleAction": "lock",
                    "inhibitWhenAudio": false,
                    "inhibitWhenCharging": false,
                    "respectInhibitors": true,
                    "timeout": 180
                },
                {
                    "idleAction": "dpms off",
                    "returnAction": "dpms on",
                    "timeout": 300
                },
                {
                    "idleAction": ["suspendThenHibernate"],
                    "timeout": 600
                }
            ]
        },
        "logo": "",
        "mediaGifSpeedAdjustment": 300,
        "sessionGifSpeed": 0.7,
        "showOverFullscreen": false
    },
    "launcher": {
        "actionPrefix": ">",
        "actions": [
            {
                "command": ["autocomplete", "calc"],
                "dangerous": false,
                "description": "Do simple math equations (powered by Qalc)",
                "enabled": true,
                "icon": "calculate",
                "name": "Calculator"
            },
            {
                "command": ["autocomplete", "scheme"],
                "dangerous": false,
                "description": "Change the current colour scheme",
                "enabled": true,
                "icon": "palette",
                "name": "Scheme"
            },
            {
                "command": ["autocomplete", "wallpaper"],
                "dangerous": false,
                "description": "Change the current wallpaper",
                "enabled": true,
                "icon": "image",
                "name": "Wallpaper"
            },
            {
                "command": ["autocomplete", "variant"],
                "dangerous": false,
                "description": "Change the current scheme variant",
                "enabled": true,
                "icon": "colors",
                "name": "Variant"
            },
            {
                "command": ["caelestia", "wallpaper", "-r"],
                "dangerous": false,
                "description": "Switch to a random wallpaper",
                "enabled": true,
                "icon": "casino",
                "name": "Random"
            },
            {
                "command": ["setMode", "light"],
                "dangerous": false,
                "description": "Change the scheme to light mode",
                "enabled": true,
                "icon": "light_mode",
                "name": "Light"
            },
            {
                "command": ["setMode", "dark"],
                "dangerous": false,
                "description": "Change the scheme to dark mode",
                "enabled": true,
                "icon": "dark_mode",
                "name": "Dark"
            },
            {
                "command": ["poweroff"],
                "dangerous": true,
                "description": "Shutdown the system",
                "enabled": true,
                "icon": "power_settings_new",
                "name": "Shutdown"
            },
            {
                "command": ["reboot"],
                "dangerous": true,
                "description": "Reboot the system",
                "enabled": true,
                "icon": "cached",
                "name": "Reboot"
            },
            {
                "command": ["logout"],
                "dangerous": true,
                "description": "Log out of the current session",
                "enabled": true,
                "icon": "exit_to_app",
                "name": "Logout"
            },
            {
                "command": ["loginctl", "lock-session"],
                "dangerous": false,
                "description": "Lock the current session",
                "enabled": true,
                "icon": "lock",
                "name": "Lock"
            },
            {
                "command": ["suspendThenHibernate"],
                "dangerous": false,
                "description": "Suspend then hibernate",
                "enabled": true,
                "icon": "bedtime",
                "name": "Sleep"
            },
            {
                "command": ["caelestia", "shell", "nexus", "open"],
                "dangerous": false,
                "description": "Configure the shell",
                "enabled": true,
                "icon": "settings",
                "name": "Settings"
            }
        ],
        "dragThreshold": 50,
        "enableDangerousActions": false,
        "enabled": true,
        "favouriteApps": [],
        "hiddenApps": [],
        "maxShown": 7,
        "maxWallpapers": 9,
        "showOnHover": false,
        "specialPrefix": "@",
        "useFuzzy": {
            "actions": false,
            "apps": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "vimKeybinds": false
    },
    "lock": {
        "enableFprint": true,
        "enableHowdy": true,
        "enabled": true,
        "hideNotifs": false,
        "maxFprintTries": 3,
        "maxHowdyTries": 3,
        "recolourLogo": true,
        "triggerHowdyOnWake": true,
        "useWallpaper": false
    },
    "nexus": {
        "networkRescanInterval": 15000,
        "wallpapersPerRow": 4
    },
    "notifs": {
        "actionOnClick": false,
        "clearThreshold": 0.3,
        "defaultExpireTimeout": 5000,
        "expandThreshold": 20,
        "expire": true,
        "fullscreen": "on",
        "fullscreenExpireTimeout": 2000,
        "groupPreviewNum": 3,
        "openExpanded": false
    },
    "osd": {
        "enableBrightness": true,
        "enableMicrophone": false,
        "enabled": true,
        "hideDelay": 2000
    },
    "paths": {
        "lockNoNotifsPic": "root:/assets/dino.png",
        "lyricsDir": "~/Music/lyrics/",
        "mediaGif": "root:/assets/bongocat.gif",
        "noNotifsPic": "root:/assets/dino.png",
        "sessionGif": "root:/assets/kurukuru.gif",
        "wallpaperDir": "~/Pictures/Wallpapers"
    },
    "services": {
        "audioIncrement": 0.1,
        "brightnessIncrement": 0.1,
        "defaultPlayer": "Spotify",
        "gpuType": "",
        "lyricsBackend": "Auto",
        "maxVolume": 1.0,
        "playerAliases": [{ "from": "com.github.th_ch.youtube_music", "to": "YT Music" }],
        "smartScheme": true,
        "useFahrenheit": false,
        "useFahrenheitPerformance": false,
        "useTwelveHourClock": false,
        "visualiserBars": 60,
        "weatherLocation": ""
    },
    "session": {
        "commands": {
            "hibernate": ["hibernate"],
            "logout": ["logout"],
            "reboot": ["reboot"
            ],
            "shutdown": ["poweroff"]
        },
        "dragThreshold": 30,
        "enabled": true,
        "icons": {
            "hibernate": "downloading",
            "logout": "logout",
            "reboot": "cached",
            "shutdown": "power_settings_new"
        },
        "vimKeybinds": false
    },
    "sidebar": {
        "dragThreshold": 80,
        "enabled": true,
        "minHoverThreshold": 200,
        "showOnHover": false
    },
    "utilities": {
        "enabled": true,
        "maxToasts": 4,
        "quickToggles": [
            {
                "enabled": true,
                "id": "wifi"
            },
            {
                "enabled": true,
                "id": "bluetooth"
            },
            {
                "enabled": true,
                "id": "mic"
            },
            {
                "enabled": true,
                "id": "settings"
            },
            {
                "enabled": true,
                "id": "gameMode"
            },
            {
                "enabled": true,
                "id": "dnd"
            },
            {
                "enabled": false,
                "id": "vpn"
            }
        ],
        "toasts": {
            "audioInputChanged": true,
            "audioOutputChanged": true,
            "capsLockChanged": true,
            "chargingChanged": true,
            "configLoaded": true,
            "dndChanged": true,
            "fullscreen": "off",
            "gameModeChanged": true,
            "kbLayoutChanged": true,
            "kbLimit": true,
            "nowPlaying": false,
            "numLockChanged": true,
            "vpnChanged": true
        },
        "vpn": {
            "enabled": false,
            "provider": [
                {
                    "displayName": "Wireguard (Your VPN)",
                    "enabled": false,
                    "interface": "your-connection-name",
                    "name": "wireguard"
                }
            ]
        }
    }
}
```

</details>

### Advanced configuration

> [!CAUTION]
> Do NOT change any of these options unless you know what you are doing. These options control the
> tokens used internally within the shell, and can cause visual issues if modified incorrectly.
> The available options may change or be removed without notice across versions.

A separate `~/.config/caelestia/shell-tokens.json` file allows editing the internal tokens without
touching the source code of the shell. These tokens affect the dimensions and appearance of visual elements,
including individual rounding, spacing, padding, font size, animation durations and curves, and the sizes of
certain components. The appearance scale values in `shell.json` are multiplied against these base
token values to produce the final computed values.

Per-monitor token overrides are also available at
`~/.config/caelestia/monitors/<monitor_name>/shell-tokens.json`.

### Home Manager Module

For NixOS users, a Home Manager module is also available.

<details><summary><code>home.nix</code></summary>

```nix
programs.caelestia = {
  enable = true;
  systemd = {
    enable = false; # if you prefer starting from your compositor
    target = "graphical-session.target";
    environment = [];
  };
  settings = {
    bar.statusIcons = [
      { id = "lockStatus"; enabled = true; }
      { id = "network"; enabled = true; }
      { id = "bluetooth"; enabled = true; }
      { id = "battery"; enabled = false; }
    ];
    paths.wallpaperDir = "~/Images";
  };
  cli = {
    enable = true; # Also add caelestia-cli to path
    settings = {
      theme.enableGtk = false;
    };
  };
};
```

The module automatically adds the shell to the path with **full functionality**. The CLI is not required; however, you can enable and configure it.

</details>

## FAQ

### Need help or support?

You can join the Caelestia Discord server for assistance and discussion [here][discord].

### I want to make my own changes to the Hyprland config!

You can add your custom Hyprland configs to `~/.config/caelestia/hypr-user.lua`.

### I want to make my own changes to other stuff!

See the [manual installation](#manual-installation) section for the corresponding repo.

### I want to disable ___ feature!

Please read the [configuring](#configuring) section.
If there is no corresponding option, make a [feature request](https://github.com/caelestia-dots/shell/issues/new?template=feature.yml).

### How do I make my colour scheme change to match my wallpaper?

Set a wallpaper via `>wallpaper` in the launcher or `caelestia wallpaper`, and set the scheme to the dynamic scheme via 
`>scheme` in the launcher or `caelestia scheme set`, e.g.:

```sh
caelestia wallpaper -f <path_to_wallpaper>
caelestia scheme set -n dynamic
```

### My wallpapers aren't showing up in the launcher!

The launcher pulls wallpapers from `~/Pictures/Wallpapers` by default. You can change this in the config. Additionally,
the launcher only shows an odd number of wallpapers at one time. If you only have 2 wallpapers, consider getting more
(or just putting one).

## Credits

Thanks to the Hyprland Discord community (especially the homies in #rice-discussion) for all the help and suggestions
for improving these dots!

A special thanks to [@outfoxxed](https://github.com/outfoxxed) for making Quickshell and the effort put into fixing issues
and implementing various feature requests.

Another special thanks to [@end_4](https://github.com/end-4) for his [config](https://github.com/end-4/dots-hyprland)
which helped me a lot with learning how to use Quickshell.

Finally, another thank you to all the configs I took inspiration from (only one for now):

-   [Axenide/Ax-Shell](https://github.com/Axenide/Ax-Shell)

## Stonks 📈

<a href="https://www.star-history.com/#caelestia-dots/shell&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date" />
 </picture>
</a>

[dots-repo]: https://github.com/caelestia-dots/caelestia
[discord]: https://caelestiashell.com/discord
