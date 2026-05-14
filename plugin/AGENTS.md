# Plugin (C++ Native Extensions) — Agent Guide

Performance-critical code and system integrations compiled as shared libraries and exposed as QML types under the `Caelestia.*` namespace.

## Module structure

```
plugin/src/Caelestia/
├── CMakeLists.txt              # Top-level: dependencies, qml_module() helper, subdir registration
├── *.hpp / *.cpp               # Root module types (Caelestia)
├── Blobs/                      # Caelestia.Blobs — GPU blob shapes (custom shaders)
├── Components/                 # Caelestia.Components — LazyListView
├── Config/                     # Caelestia.Config — GlobalConfig, Tokens, per-monitor config
├── Images/                     # Caelestia.Images — Image caching provider
├── Internal/                   # Caelestia.Internal — Arc gauge, sparkline, visualiser, Hyprland extras
├── Models/                     # Caelestia.Models — FileSystemModel
└── Services/                   # Caelestia.Services — Audio collection, beat tracker, cava provider
```

## QML modules produced

| C++ module | QML import | Key types |
|------------|-----------|-----------|
| `Caelestia` | `import Caelestia` | `ImageAnalyser`, `Qalculator`, `AppDb`, `Requests`, `Toaster` |
| `Caelestia.Config` | `import Caelestia.Config` | `GlobalConfig` (singleton), `Config` (attached), `Tokens` (attached) |
| `Caelestia.Components` | `import Caelestia.Components` | `LazyListView` |
| `Caelestia.Internal` | `import Caelestia.Internal` | `ArcGauge`, `SparklineItem`, `VisualiserBars`, `HyprDevices`, `HyprExtras` |
| `Caelestia.Services` | `import Caelestia.Services` | `BeatTracker`, `CavaProvider`, `AudioCollector` |
| `Caelestia.Blobs` | `import Caelestia.Blobs` | `BlobShape`, `BlobGroup`, `BlobInvertedRect` |
| `Caelestia.Images` | `import Caelestia.Images` | `CachingImageProvider` |
| `Caelestia.Models` | `import Caelestia.Models` | `FileSystemModel` |

## C++ conventions

### Style
- `.clang-format` in repo root — LLVM-based, 4-space indent, 120 column limit
- Namespace: `caelestia::<module>` (e.g. `caelestia::config`, `caelestia::services`)
- Headers: `#pragma once`
- Naming: classes PascalCase, methods/members camelCase, prefixed `m_` for private members

### QML type exposure
```cpp
class MyType : public QObject {
    Q_OBJECT
    QML_ELEMENT                    // Registers type with QML engine
    // or QML_SINGLETON for singletons

    Q_PROPERTY(QString name READ name NOTIFY nameChanged)

public:
    explicit MyType(QObject* parent = nullptr);
    [[nodiscard]] QString name() const;

signals:
    void nameChanged();

private:
    QString m_name;
};
```

### Config system macros
```cpp
// Simple property with default value
CONFIG_PROPERTY(bool, enabled, true)
CONFIG_PROPERTY(int, maxItems, 10)
CONFIG_PROPERTY(QString, label, "default")

// Nested config object
CONFIG_SUBOBJECT(AppearanceConfig, appearance)
```

These macros generate the Q_PROPERTY boilerplate, JSON deserialization, and default values automatically.

## Build system

Each subdirectory has a `CMakeLists.txt` using the `qml_module()` helper:

```cmake
qml_module(target-name
    URI Caelestia.ModuleName
    SOURCES file.hpp file.cpp
    LIBRARIES PkgConfig::SomeDep
)
```

This registers the QML module, handles installation of `.so`, `qmldir`, and `.qmltypes` files.

## Build workflow

```bash
cmake --build build              # Compile
sudo cmake --install build       # Install .so files to /usr/lib/qt6/qml/Caelestia/
```

Both steps required after any C++ change. QML-only changes need no rebuild.

## Dependencies

| Library | Package | Used by |
|---------|---------|---------|
| `libqalculate` | `libqalculate` (pacman) | Calculator action in launcher |
| `libpipewire-0.3` | `libpipewire` (pacman) | Audio collection for visualiser |
| `aubio` | `aubio` (pacman) | Beat detection |
| `libcava` / `cava` | `libcava` (AUR) | Audio visualiser bars |

## Adding a new C++ type

1. Create `.hpp` / `.cpp` in the appropriate subdirectory
2. Add `QML_ELEMENT` macro to the class
3. Add files to the `SOURCES` list in the subdirectory's `CMakeLists.txt`
4. Rebuild and reinstall
5. Import in QML via `import Caelestia.<Module>`
