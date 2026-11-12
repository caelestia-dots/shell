qml_module(caelestia-components
    URI Caelestia.Components
    SOURCES
        animatedrepeater.cpp
        lazyviewbase.cpp
        lazylistview.cpp
        lazygridview.cpp
        wavyline.cpp
        buttonrow.cpp
        circularindicatormanager.cpp
        linearindicatormanager.cpp
        sparklineitem.cpp
        visualiserbars.cpp
        roundedmask.cpp
        oklchwheel.cpp
        imageexporter.cpp
        imageloader.cpp
        screencapture.cpp
        annotationshape.cpp
        annotationdocument.cpp
        annotationcanvas.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::QmlModels
        caelestia-core
        caelestia::caelestia
    DEPENDENCIES
        Caelestia
)

qt_add_shaders(caelestia-components "components_shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/"
    FILES
        shaders/roundedmask.frag
        shaders/roundedmask.vert
        shaders/oklchwheel.frag
        shaders/oklchwheel.vert
)
