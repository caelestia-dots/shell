qml_module(caelestia-internal
    URI Caelestia.Internal
    SOURCES
        circularbuffer.hpp circularbuffer.cpp
        circularindicatormanager.hpp circularindicatormanager.cpp
        linearindicatormanager.hpp linearindicatormanager.cpp
        hyprdevices.hpp hyprdevices.cpp
        hyprextras.hpp hyprextras.cpp
        logindmanager.cpp
        sparklineitem.hpp sparklineitem.cpp
        visualiserbars.hpp visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Network
)
