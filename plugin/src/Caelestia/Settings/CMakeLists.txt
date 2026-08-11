qml_module(caelestia-settings
    URI Caelestia.Settings
    SOURCES
        node.cpp
        objectnode.cpp
        settingsfile.cpp
)
target_include_directories(caelestia-settings PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
