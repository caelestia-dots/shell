qml_module(caelestia-scheme
    URI Caelestia.Scheme
    SOURCES
        colours.cpp
        schemehandles.cpp
        schemeopener.cpp
        wallpapers.cpp
    QML_SINGLETONS
        Colours.qml
    LIBRARIES
        Qt::Quick
        caelestia-config
        caelestia-models
        caelestia::caelestia
    DEPENDENCIES
        Caelestia.Models
)
