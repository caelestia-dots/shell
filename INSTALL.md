# Installation Guide

Personal fork of [caelestia-shell](https://github.com/caelestia-dots/shell) for use on Arch Linux with Hyprland and Omarchy.

## Prerequisites

- Arch Linux with Hyprland
- Omarchy desktop environment

## Dependencies

### Quickshell ≥ 0.3.0

Caelestia requires Quickshell 0.3.0 or newer (the git version is recommended by upstream).

> **Omarchy mirror note:** Omarchy mirrors are delayed ~30 days behind upstream Arch repos.
> If `quickshell` 0.3.0 and `cpptrace` are not yet available in your mirrors, download them
> directly from an Arch mirror:
>
> ```bash
> # Download from current Arch mirror
> curl -LO "https://geo.mirror.pkgbuild.com/extra/os/x86_64/cpptrace-1.0.4-2-x86_64.pkg.tar.zst"
> curl -LO "https://geo.mirror.pkgbuild.com/extra/os/x86_64/quickshell-0.3.0-1-x86_64.pkg.tar.zst"
>
> # Install both together (cpptrace is a dependency of quickshell)
> sudo pacman -U cpptrace-1.0.4-2-x86_64.pkg.tar.zst quickshell-0.3.0-1-x86_64.pkg.tar.zst
>
> # Prevent delayed mirrors from downgrading on next pacman -Syu
> # Add to IgnorePkg line in /etc/pacman.conf:
> #   IgnorePkg = quickshell cpptrace
> # Remove the ignore once Omarchy mirrors catch up.
>
> # Clean up downloaded files
> rm cpptrace-*.pkg.tar.zst quickshell-*.pkg.tar.zst
> ```
>
> Alternatively, check the exact versions at:
> - https://archlinux.org/packages/extra/x86_64/quickshell/
> - https://archlinux.org/packages/extra/x86_64/cpptrace/

If your mirrors are current, simply:

```bash
sudo pacman -S quickshell
```

### System packages (pacman)

```bash
sudo pacman -S \
  cmake \
  ninja \
  ttf-material-symbols-variable \
  aubio
```

### AUR packages (yay)

```bash
yay -S libcava
```

### Summary of all dependencies

| Package | Source | Purpose |
|---------|--------|---------|
| `quickshell` ≥ 0.3.0 | pacman (or manual, see above) | Shell runtime |
| `cpptrace` | pacman (or manual, see above) | Dependency of quickshell 0.3.0 |
| `cmake` | pacman | Build tool |
| `ninja` | pacman | Build tool |
| `ttf-material-symbols-variable` | pacman | Icon font used by caelestia |
| `aubio` | pacman | Audio beat detection (visualiser) |
| `libcava` | AUR | Audio visualiser library |

## Setup

### 1. Clone the repo

```bash
git clone git@github.com:golgor/shell.git ~/Code/Personal/shell
cd ~/Code/Personal/shell

# Track upstream for future merges
git remote add upstream git@github.com:caelestia-dots/shell.git
```

### 2. Fetch upstream tags (needed for build)

```bash
git fetch upstream --tags
```

### 3. Symlink into quickshell config

```bash
# Back up any existing quickshell config
mv ~/.config/quickshell ~/.config/quickshell.bak 2>/dev/null

# Create config dir with symlink
mkdir -p ~/.config/quickshell
ln -s ~/Code/Personal/shell ~/.config/quickshell/caelestia
```

### 4. Build

```bash
cd ~/Code/Personal/shell
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DVERSION="v1.6.2" \
  -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"

cmake --build build
```

### 5. Install

```bash
sudo cmake --install build
```

This installs:
- QML plugins to `/usr/lib/qt6/qml/Caelestia/`
- Generated `shell.qml` entry point into the symlinked config dir
- Library files to `/usr/lib/caelestia/`

### 6. Create user config directory

```bash
mkdir -p ~/.config/caelestia
```

Customizations go in `~/.config/caelestia/shell.json`. See upstream [README](https://github.com/caelestia-dots/shell#configuring) for all options.

### 7. Launch

```bash
quickshell -c caelestia
```

## File layout

```
~/Code/Personal/shell/                 ← fork repo (origin: golgor/shell)
    ↓ symlink
~/.config/quickshell/caelestia/        ← quickshell reads config from here
~/.config/caelestia/shell.json         ← user customization (optional)
```

## Rebuilding after changes

If you modify any C++ source files in `plugin/`:

```bash
cd ~/Code/Personal/shell
cmake --build build
sudo cmake --install build
```

QML file changes are picked up automatically via the symlink (quickshell live-reloads).

## Updating from upstream

```bash
cd ~/Code/Personal/shell
git fetch upstream
git merge upstream/main
# Rebuild if needed
cmake --build build
sudo cmake --install build
```
