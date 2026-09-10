qml_module(caelestia-components
    URI Caelestia.Components
    SOURCES
        lazylistview.cpp
        wavyline.cpp
        buttonrow.cpp
        circularindicatormanager.cpp
        linearindicatormanager.cpp
        sparklineitem.cpp
        visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        caelestia-core
    DEPENDENCIES
        Caelestia
)
