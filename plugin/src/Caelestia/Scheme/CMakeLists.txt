qml_module(caelestia-scheme
    URI Caelestia.Scheme
    SOURCES
        colours.cpp
        wallpapers.cpp
    QML_SINGLETONS
        Colours.qml
    LIBRARIES
        caelestia-config
        caelestia::caelestia
)
