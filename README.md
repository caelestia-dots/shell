<h1 align=center>caelestia-shell</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=d3bfe6)
![Ko-Fi donate](https://img.shields.io/badge/donate-kofi?style=for-the-badge&logo=ko-fi&logoColor=ffffff&label=ko-fi&labelColor=101418&color=f16061&link=https%3A%2F%2Fko-fi.com%2Fsoramane)

</div>

> [!WARNING]
> I am currently working on a complete overhaul for everything but the shell which should fix most issues with installation.
> As such, I will not be working on the shell until the overhaul is finished. I will still try to answer issues, however other
> than minor issues, I will most likely not be able to fix them (same goes for feature requests). PRs are still welcome though!
> 
> Some breaking changes:
> - Rename the `scripts` repo -> `cli`
> - Rename the `hypr` repo -> `caelestia` (this will be the main repo after the change)
> - Merge all other repos (except this and `cli`) into `caelestia`
> - Installation for the `shell` and `cli` will be done via AUR packages; `caelestia` will have a meta package and an install script (should fix most installation issues)
> - Overhaul the scheme system (should fix a few bugs with that and make it cleaner in general)

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

caelestia-shell is a feature-rich, customizable desktop shell environment specifically designed for the Hyprland Wayland compositor. Built using QML and the Quickshell framework, it offers a modern and fluid user experience.

## Core Technologies

- **Hyprland:** A dynamic tiling Wayland compositor that `caelestia-shell` is designed to integrate with, providing a modern and fluid window management experience. ([Hyprland Website](https://hyprland.org))
- **Quickshell:** The QML-based framework used to build `caelestia-shell`. It allows for the creation of custom shell components and user interfaces. ([Quickshell Website](https://quickshell.outfoxxed.me))
- **QML (Qt Modeling Language):** A declarative language used for designing user interfaces and defining their behavior. Most of `caelestia-shell`'s UI and logic is written in QML.

## Features

### Bar
Displays an OS icon, customizable workspaces (configurable count, labels, activity indicators, and window previews via popups), active window title, a system tray, clock, status icons (network, Bluetooth, battery) with detailed popout views, and a power button.
- *Configuration: `config/BarConfig.qml`*

### Dashboard
Accessible via a keyboard shortcut, the dashboard presents a user profile picture (sourced from `~/.face`), current weather information, date and time, a calendar, system resource monitors (CPU, RAM, disk usage), and media player controls.
- *Configuration: `config/DashboardConfig.qml`*

### Launcher
A searchable application launcher. It may also include quick actions or wallpaper switching capabilities.
- *Configuration: `config/LauncherConfig.qml`*

### Notifications
A system for displaying notifications from applications and the system itself, ensuring users stay informed about important events.
- *Configuration: `config/NotifsConfig.qml`*

### On-Screen Display (OSD)
Provides visual feedback for various actions, such as volume adjustments, brightness changes, and other system status indicators.
- *Configuration: `config/OsdConfig.qml`*

### Session Management
Manages the user session, including options for locking the screen, logging out, restarting, or shutting down the system.
- *Configuration: `config/SessionConfig.qml`*

### Customizable Appearance
Offers extensive customization options for the shell's visual elements, including global settings for corner rounding, spacing, padding, fonts, and animations. Color schemes can also be defined and applied.
- *Configuration: `config/Appearance.qml`*

## Installation

### Automated installation (recommended)

Install [`caelestia-scripts`](https://github.com/caelestia-dots/scripts) and run `caelestia install shell`.

### Manual installation

Install all [dependencies](https://github.com/caelestia-dots/scripts/blob/main/install/shell.fish#L10), then
clone this repo into `$XDG_CONFIG_HOME/quickshell/caelestia`. This directory will also be where you customize the shell (see 'Features' section above for configuration files). Then run `qs -c caelestia` to start the shell.

## Usage

The shell can be started in two ways: via systemd or manually running `caelestia shell`.

### Via systemd

The install script creates and enables the systemd service `caelestia-shell.service` which should automatically start the
shell on login.

### Via command

If not on a system that uses systemd, you can manually start the shell via `caelestia-shell`.
To autostart it on login, you can use an `exec-once` rule in your Hyprland config:
```
exec-once = caelestia shell
```

### Shortcuts/IPC

All keybinds are accessible via Hyprland [global shortcuts](https://wiki.hyprland.org/Configuring/Binds/#dbus-global-shortcuts).
For a preconfigured setup, install [`caelestia-hypr`](https://github.com/caelestia-dots/hypr) via `caelestia install hypr` or see
[this file](https://github.com/caelestia-dots/hypr/blob/main/hyprland/keybinds.conf#L1-L29) for an example on how to use global
shortcuts.

All IPC commands can be accessed via `caelestia shell ...`. For example
```sh
caelestia shell mpris getActive trackTitle
```

The list of IPC commands can be shown via `caelestia shell help`:
```
> caelestia shell help
target mpris
  function stop(): void
  function play(): void
  function next(): void
  function getActive(prop: string): string
  function list(): string
  function playPause(): void
  function pause(): void
  function previous(): void
target drawers
  function list(): string
  function toggle(drawer: string): void
target wallpaper
  function list(): string
  function get(): string
  function set(path: string): void
target notifs
  function clear(): void
```

### Configuration
`caelestia-shell` is configured by editing QML files located in the `$XDG_CONFIG_HOME/quickshell/caelestia/config/` directory. If you installed manually, this is the same directory where you cloned the repository.

Key configuration files include:
- `Appearance.qml`: Controls global theming aspects like rounding, spacing, padding, fonts, and animations. (See "Customizable Appearance" under Features).
- `BarConfig.qml`: Configures the bar, its elements, and behavior. (See "Bar" under Features).
- `DashboardConfig.qml`: Manages the content and layout of the dashboard. (See "Dashboard" under Features).
- `LauncherConfig.qml`: Defines settings for the application launcher. (See "Launcher" under Features).
- `NotifsConfig.qml`: Adjusts notification appearance and behavior. (See "Notifications" under Features).
- `OsdConfig.qml`: Configures the on-screen display elements. (See "On-Screen Display (OSD)" under Features).
- `SessionConfig.qml`: Handles session-related options like logout and lock screen. (See "Session Management" under Features).

Changes to these configuration files typically require a shell reload to take effect. This can usually be done by restarting the `caelestia-shell.service` if using systemd, or by re-running `qs -c caelestia` if you started it manually.

#### Specific Asset Paths
- **Profile Picture (PFP):** The dashboard reads the user's profile picture from `~/.face`. Place your desired image file at this location.
- **Wallpapers:** The wallpaper switcher sources images from `~/Pictures/Wallpapers/`. Store your wallpaper collection in this directory. Currently, the shell needs to be restarted to recognize new wallpapers in this folder. To set the wallpaper via command line, use `caelestia wallpaper set <path_to_image>`.

## Contributing

We welcome contributions to `caelestia-shell`! If you're interested in helping improve the project, please follow these standard guidelines:

1.  **Fork the repository** on GitHub.
2.  **Create a new branch** for your feature or bug fix: `git checkout -b my-awesome-feature`.
3.  **Make your changes** and commit them with clear, descriptive messages.
4.  **Push your branch** to your fork: `git push origin my-awesome-feature`.
5.  **Submit a pull request** to the main `caelestia-shell` repository.

For significant changes, such as new features or major refactoring, please open an issue first to discuss your ideas with the maintainers. This helps ensure that your contributions align with the project's goals and ongoing development.

While the project is currently undergoing a significant overhaul (as mentioned in the warning at the top of this document), pull requests for bug fixes or features that have been discussed and agreed upon are still very welcome. We appreciate your understanding and effort in helping make `caelestia-shell` better!

## Credits

Thanks to the Hyprland discord community (especially the homies in #rice-discussion) for all the help and suggestions
for improving these dots!

A special thanks to [@outfoxxed](https://github.com/outfoxxed) for making Quickshell and the effort put into fixing issues
and implementing various feature requests.

Another special thanks to [@end_4](https://github.com/end-4) for his [config](https://github.com/end-4/dots-hyprland)
which helped me a lot with learning how to use Quickshell.

Finally another thank you to all the configs I took inspiration from (only one for now):
- [Axenide/Ax-Shell](https://github.com/Axenide/Ax-Shell)

## License

This project is licensed under the GNU General Public License Version 3. See the [LICENSE](LICENSE) file for details.

## Stonks 📈

<a href="https://www.star-history.com/#caelestia-dots/shell&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date" />
 </picture>
</a>
