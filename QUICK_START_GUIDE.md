# Caelestia Shell Modification Guide

This guide provides a developer-focused overview of the Caelestia Shell codebase. Its purpose is to help you understand the project structure and learn how to modify the QML code to customize the shell to your liking.

## Core Concepts

The shell is built with **Quickshell**, and its user interface is written almost entirely in **QML**.

- **`shell.qml`**: This is the main entry point of the application. It's responsible for loading and integrating all the different modules and services that make up the shell.
- **Configuration (`~/.config/caelestia/shell.json`)**: Most visual and behavioral tweaks can be made through this JSON file. The structure of this file is defined by the QML files in the `config/` directory. Before diving deep into the code, always check if the change you want can be made here.
- **Running the Shell**: To see your changes, you can run the shell using `qs -c caelestia` or `caelestia shell -d` from within your `nix develop` environment.

---

## Directory Structure Explained

Here is a breakdown of the key directories and their purposes.

### 📂 `config/`
**Purpose**: Defines the configuration options available in `shell.json`.

- If you want to add a new customizable variable (e.g., a new color, a new size option), you would first add it to one of the files in this directory.
- Files like `AppearanceConfig.qml`, `BarConfig.qml`, and `DashboardConfig.qml` directly correspond to sections in the `shell.json` file.
- **Start here if you want to make an existing component more customizable.**

### 📂 `services/`
**Purpose**: Backend data providers for the UI.

- These files are not UI components. Instead, they fetch and process data from the system or external APIs.
- Examples include `Audio.qml` (for volume), `SystemUsage.qml` (for CPU/RAM), `Weather.qml`, and `Hyprland.qml` (for window manager integration).
- **Modify files here if you want to change how data is fetched or processed.** For example, changing the weather provider or adding a new system metric to monitor.

### 📂 `modules/`
**Purpose**: The major, high-level UI components of the shell.

- This is where the main UI of the shell is defined. Each subdirectory corresponds to a distinct feature.
- `bar/`: The top status bar.
- `dashboard/`: The main dashboard/overview screen.
- `controlcenter/`: The settings and quick toggles panel.
- `launcher/`: The application launcher.
- `lock/`: The lock screen.
- `notifications/`: The notification popups and center.
- `osd/`: The on-screen display for things like volume or brightness changes.
- **Modify files here to change the layout, appearance, or behavior of a specific part of the shell.**

### 📂 `components/`
**Purpose**: Reusable, low-level UI building blocks.

- This directory is like a component library for the entire shell. It contains the basic elements that are used to build the larger modules.
- `controls/`: Basic interactive elements like `StyledRadioButton.qml`, `StyledSlider.qml`, `StyledTextField.qml`.
- `containers/`: Wrapper components like `StyledWindow.qml` and `StyledFlickable.qml`.
- `effects/`: Visual effects like `Elevation.qml` (for shadows) and `Colouriser.qml`.
- **Modify files here if you want to make a fundamental change to a specific type of UI element across the entire shell.** For example, changing how all sliders look and feel.

### 📂 `utils/`
**Purpose**: Miscellaneous helper functions and utilities.

- Contains globally used helper QML files like `Icons.qml` and `Paths.qml`. These are not UI components but provide useful functions that can be called from anywhere.

### 📂 `assets/`
**Purpose**: Static assets.

- Contains images, icons, `.gif` files, and shaders.
- It also contains the C++ source for the `beat_detector.cpp`, which is a separate component that needs to be compiled.

---

## How to Approach Modifications

1.  **For Simple Tweaks (Colors, Sizes, Visibility):**
    - Always start by examining `~/.config/caelestia/shell.json` and the files in the `config/` directory. The option you need might already exist.

2.  **To Change the Layout of a Major Feature (e.g., the Dashboard):**
    - Go to the relevant subdirectory in `modules/`. For the dashboard, this would be `modules/dashboard/`.
    - The main file is often named after the directory (e.g., `Dash.qml`). From there, you can trace the logic to the specific sub-component you want to change.

3.  **To Change a Basic UI Element (e.g., all buttons):**
    - Find the corresponding component in `components/controls/`. Modifying it here will apply the change globally.

4.  **To Add a New Data Source (e.g., a stock ticker):**
    - Create a new QML file in `services/` to handle the data fetching logic.
    - Import and use your new service in the `modules/` component where you want to display the data.
