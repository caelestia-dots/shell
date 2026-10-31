qml_module(caelestia-multimedia
    URI Caelestia.Multimedia
    SOURCES
        visualsource.cpp
        imagecache.cpp
        ktxencoder.cpp
        visualanalyser.cpp
        remotecache.cpp
    QML_FILES
        Visual.qml
    LIBRARIES
        Qt::Quick
        Qt::Multimedia
        Qt::Concurrent
        Qt::Network
        caelestia::caelestia
        rgbcx
)
