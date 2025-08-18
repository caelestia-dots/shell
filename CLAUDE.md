# Caelestia Shell Developer Guide

This guide provides a comprehensive overview of the Caelestia Shell codebase. Its purpose is to help you understand the project structure, development conventions, and how to modify the QML code to customize the shell.

---

## 1. Project Overview

Caelestia Shell is a desktop environment built with **Quickshell** for the **Hyprland** window manager on Linux. It is written primarily in **QML**.

- **Main Entry Point**: `shell.qml` is the root file that loads all other modules.
- **Configuration**: The shell is configured via `~/.config/caelestia/shell.json`. The structure of this JSON file is defined by the QML components in the `config/` directory.
- **Styling**: The shell uses a dynamic color system that adapts to your wallpaper. Do not hardcode colors; use the `Colours` service and theme palettes.

---

## 2. Installation and Building

### Dependencies

Ensure you have the dependencies from the `README.md` installed, including `quickshell-git`, `hyprland`, `cava`, etc.

### Building and Running

The recommended method is using the Nix development environment:

```sh
# Enter the development shell
nix develop

# Run the shell
qs -c caelestia
# OR for debug mode
caelestia shell -d
```

### Code Formatting

This project uses `alejandra` for QML formatting. To format your code, run:

```sh
nix fmt
```

---

## 3. Project Structure

- **`config/`**: Defines the structure of the `shell.json` configuration file.
- **`services/`**: Backend-like data providers for the UI (e.g., `Audio.qml`, `SystemUsage.qml`, `Weather.qml`).
- **`modules/`**: The major, high-level UI components (e.g., `bar/`, `dashboard/`, `launcher/`, `lock/`).
- **`components/`**: Reusable, low-level UI building blocks (buttons, sliders, etc.).
- **`utils/`**: Miscellaneous helper functions.
- **`assets/`**: Static files like images, shaders, and the C++ source for the beat detector.

---

## 4. How to Modify the Dashboard

This section details the process of changing the dashboard's layout, based on the recent request to implement a new grid design.

### Understanding the Dashboard Files

- **`modules/dashboard/Content.qml`**: The main container for the dashboard pages. It uses a `Flickable` component to allow scrolling between different panes.
- **`modules/dashboard/Dash.qml`**: The component for the *first* dashboard page. This is where the main grid layout is defined.
- **`modules/dashboard/dash/`**: A directory containing the individual widgets used within the `Dash.qml` grid (e.g., `Weather.qml`, `Calendar.qml`, `Media.qml`).

### The Modification Process

The goal is to change the layout of the first dashboard page without removing the ability to scroll to other pages (like the full-screen media player or performance view).

1.  **Do Not Modify `Content.qml`**: Leave `Content.qml` as is. Its `Flickable` and `Tabs` are necessary for page scrolling.

2.  **Modify the Grid in `Dash.qml`**: The primary file to edit is `modules/dashboard/Dash.qml`. This file contains a `GridLayout`.
    - You can rearrange widgets by changing their `Layout.row` and `Layout.column` attached properties.
    - You can make widgets span multiple cells with `Layout.rowSpan` and `Layout.columnSpan`.
    - You can add or remove widgets from the grid.

3.  **Edit or Create Widgets**: The individual widgets are located in the `modules/dashboard/dash/` directory.
    - To change the appearance of the weather widget, you would edit `modules/dashboard/dash/Weather.qml`.
    - If you need a new widget in the grid, you first create its QML file in this directory, and then add it to the `GridLayout` in `Dash.qml`.

### Example: Reverting to the 2x3 Grid Layout

To achieve the 2x3 grid layout as previously discussed, the `Dash.qml` file was modified to arrange the `Weather`, `User`, `Media`, `DateTime`, `Calendar`, and a new `CavaVisualizer` component into a two-row, three-column grid. The `Resources` widget was removed, and the `CavaVisualizer.qml` file was created to house the audio visualizer.

---

## 5. IPC and Scripting

The shell exposes an IPC interface through the `caelestia` command-line tool, allowing for scripting and integration with other tools. The available commands can be listed with `caelestia shell -s`.

Keybinds are managed through Hyprland's global shortcuts, which can call these IPC commands.