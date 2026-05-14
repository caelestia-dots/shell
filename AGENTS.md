# Caelestia Shell — Agent Guide

Personal fork of [caelestia-shell](https://github.com/caelestia-dots/shell). A Quickshell (QML) desktop shell for Hyprland on Arch Linux with Omarchy.

## Pending work

See `TODO.md` for investigated and prioritized tasks with effort estimates, root cause analysis, and implementation guidance.

## Architecture

Four layers, from high to low:

| Layer | Path | Role |
|-------|------|------|
| **Modules** | `modules/` | Feature UIs (bar, dashboard, notifications, launcher, etc.) |
| **Components** | `components/` | Reusable UI primitives shared across modules |
| **Services** | `services/` | Singleton data layer — no visuals, only state and I/O |
| **Plugin** | `plugin/` | C++ native extensions exposed as QML types under `Caelestia.*` |

Supporting directories:
- `utils/` — Pure-logic singletons and JS helper scripts (fuzzy search, string utils, paths)
- `assets/` — Static resources (images, shaders, PAM config)
- `scripts/` — Build/lint tooling (not runtime)

## Entry point

`shell.qml` is the root. It imports modules and instantiates them inside a `ShellRoot`. Per-screen instances are created in `modules/drawers/Drawers.qml` using `Variants` over `Screens.screens`.

## Config system

- **C++ backed**: `Caelestia.Config` module, rooted at `GlobalConfig` singleton
- **User config**: `~/.config/caelestia/shell.json` (not in this repo)
- **Per-monitor overrides**: `~/.config/caelestia/monitors/<screen-name>/shell.json`
- **Design tokens**: `Tokens` attached property (accessed as `Tokens.padding.normal`, `Tokens.anim.durations.normal`, `Tokens.font.size.smaller`, etc.)
- **Colors**: `Colours` singleton in `services/Colours.qml` with Material 3 palette

## QML coding conventions

### Pragmas
- `pragma ComponentBehavior: Bound` on any file that uses `Repeater`, `Variants`, `DelegateChooser`, or other delegate-based types
- `pragma Singleton` on all service and utility singletons

### Import order
```qml
pragma ComponentBehavior: Bound
pragma Singleton

import "./relative"           // relative imports first
import QtQuick                // Qt modules
import QtQuick.Layouts
import Quickshell             // Quickshell modules
import Quickshell.Hyprland
import Caelestia.Config       // Caelestia C++ modules
import qs.components          // qs.* module imports
import qs.services
```

### Naming
- **Files**: PascalCase, name matches the root type (`Clock.qml` exports `Clock`)
- **Properties**: camelCase, use `readonly` when not externally writable
- **Required properties**: always typed — `required property string name`, `required property ShellScreen screen`
- **Functions**: camelCase, always type params and return — `function distSq(x: real, y: real): real`
- **Inline components**: `component Name: BaseType { }` — scoped to the file
- **IDs**: camelCase, `id: root` on the root object of each file

### Patterns
- **Root id**: The root object in every file should have `id: root`
- **Styled wrappers**: Use `StyledRect`, `StyledText`, `StyledClippingRect` instead of raw Qt types for themed defaults
- **Animations**: Use `Anim`, `CAnim`, `AnchorAnim` types with `Anim.Type` enum — never hardcode durations/easings
- **Design tokens**: Read sizes, padding, spacing, fonts from `Tokens` attached property — never hardcode pixel values
- **Colors**: Read from `Colours.palette.*` or `Colours.tPalette.*` — never hardcode color values
- **Loaders**: Use `Loader` with `active` / `sourceComponent` for conditional or lazy content
- **State transitions**: Prefer QML `states` / `transitions` over imperative animation triggers

### Anti-patterns
- Do not hardcode colors, font sizes, padding, or animation durations
- Do not use `childrenRect` for sizing (causes binding loops)
- Do not use `id` references across file boundaries — pass data via `required property`

## C++ conventions

- Namespace: `caelestia::*` (e.g. `caelestia::config`, `caelestia::services`)
- Style: `.clang-format` in repo root (LLVM-based, 4-space indent, 120 col limit)
- QML exposure: `QML_ELEMENT` macro, registered via `qml_module()` in CMake
- Config macros: `CONFIG_PROPERTY(type, name, default)`, `CONFIG_SUBOBJECT(Type, name)`

## Git workflow

This is a **personal fork** of `caelestia-dots/shell`. All PRs must target this fork — never the upstream.

```
origin    git@github.com:golgor/shell.git      ← PRs go here
upstream  git@github.com:caelestia-dots/shell.git  ← NEVER open PRs here
```

When creating a PR always pass `--repo golgor/shell` explicitly:

```bash
gh pr create --repo golgor/shell --base main --head <branch> ...
```

## Commit convention

```
module: change description
```

Module names match directory names: `bar`, `dashboard`, `services`, `components`, `plugin`, `config`, `lock`, `launcher`, `notifications`, `sidebar`, `osd`, `utils`, `docs`, `build`.

For cross-cutting changes use `chore`, `fix`, `feat`, or `refactor`.

## Build and install

```bash
cd ~/Code/Personal/shell

# Configure (first time or after CMakeLists changes)
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DVERSION="v1.6.2" \
  -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"

# Build
cmake --build build

# Install (needed after C++ changes)
sudo cmake --install build
```

QML file changes are picked up automatically via the symlink — no rebuild needed unless C++ files change.

## Launch

```bash
quickshell -c caelestia
```
