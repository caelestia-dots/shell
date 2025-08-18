# Caelestia Shell

## Project Overview

This repository contains the source code for the Caelestia Shell, a desktop shell environment built with **Quickshell** and designed for the **Hyprland** window manager on Linux. It is part of the larger "caelestia-dots" collection of dotfiles.

The shell is primarily written in **QML**, a declarative language for creating user interfaces with the Qt framework. It also includes a C++ component for audio beat detection. The project is managed using the **Nix** package manager, with its configuration defined in `flake.nix`.

The shell's appearance and behavior are highly configurable through a central `shell.json` file, which is parsed by `config/Config.qml`. The main entry point for the application is `shell.qml`.

## Building and Running

### Nix Environment

The recommended way to work with this project is through the Nix development environment. To enter the development shell, run:

```sh
nix develop
```

This will provide a shell with all the necessary dependencies and environment variables set.

### Manual Installation and Running

For a manual setup, you will need to install the dependencies listed in the `README.md` file. The key dependencies include:

*   `quickshell-git`
*   `hyprland`
*   `ddcutil`
*   `brightnessctl`
*   `cava`
*   `qt6-declarative`

Once the dependencies are installed, you can run the shell using the following command:

```sh
qs -c caelestia
```

Alternatively, the `caelestia` command-line tool can be used:

```sh
caelestia shell -d
```

### Building the Beat Detector

The project includes a C++ beat detector that needs to be compiled separately.

```sh
g++ -std=c++17 -Wall -Wextra -I/usr/include/pipewire-0.3 -I/usr/include/spa-0.2 -I/usr/include/aubio -o beat_detector assets/beat_detector.cpp -lpipewire-0.3 -laubio
```

The compiled binary should be placed in `/usr/lib/caelestia/beat_detector`, or the `CAELESTIA_BD_PATH` environment variable should be set to its location.

## Development Conventions

### Code Style

The QML code is formatted with `alejandra`, which is specified in the `flake.nix` file. To format the code, run:

```sh
nix fmt
```

### Configuration

The shell is configured through `~/.config/caelestia/shell.json`. The available configuration options are defined as QML components in the `config/` directory. For development, you can modify this file to test different settings.

### IPC and Scripting

The shell exposes an IPC interface through the `caelestia` command-line tool, allowing for scripting and integration with other tools. The available commands can be listed with `caelestia shell -s`. Keybinds are managed through Hyprland's global shortcuts.
