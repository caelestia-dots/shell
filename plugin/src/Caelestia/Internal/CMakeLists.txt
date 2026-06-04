qml_module(caelestia-internal
    URI Caelestia.Internal
    PLUGIN_SOURCE plugin.cpp
    SOURCES
        circularbuffer.cpp
        circularindicatormanager.cpp
        linearindicatormanager.cpp
        hyprdevices.cpp
        hyprextras.cpp
        logindmanager.cpp
        sparklineitem.cpp
        translationloader.cpp
        visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Network
        Qt::DBus
)

# Where to look for installed translations at runtime.
target_compile_definitions(caelestia-internal PRIVATE
    CAELESTIA_TRANSLATIONS_DIR="/${INSTALL_QSCONFDIR}/translations"
)
