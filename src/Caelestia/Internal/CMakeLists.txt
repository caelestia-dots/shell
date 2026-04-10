qml_module(caelestia-internal
    URI Caelestia.Internal
    SOURCES
        arcgauge.hpp arcgauge.cpp
        cachingimagemanager.hpp cachingimagemanager.cpp
        circularbuffer.hpp circularbuffer.cpp
        circularindicatormanager.hpp circularindicatormanager.cpp
        hyprdevices.hpp hyprdevices.cpp
        hyprextras.hpp hyprextras.cpp
        logindmanager.hpp logindmanager.cpp
        sparklineitem.hpp sparklineitem.cpp
        visualiserbars.hpp visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Network
        Qt::DBus
)
