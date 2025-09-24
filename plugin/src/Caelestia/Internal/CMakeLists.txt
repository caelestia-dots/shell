qml_module(caelestia-internal
    URI Caelestia.Internal
    SOURCES
        cachingimagemanager.hpp cachingimagemanager.cpp
        circularindicatormanager.hpp circularindicatormanager.cpp
        hyprdevices.hpp hyprdevices.cpp
        hyprextras.hpp hyprextras.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Network
)
