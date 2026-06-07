qml_module(caelestia-images
    URI Caelestia.Images
    SOURCES
        cachingimageprovider.hpp cachingimageprovider.cpp
        imagecacher.hpp imagecacher.cpp
        iutils.hpp iutils.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
)
