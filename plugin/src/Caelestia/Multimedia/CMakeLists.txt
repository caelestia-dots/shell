qml_module(caelestia-multimedia
    URI Caelestia.Multimedia
    SOURCES
        visualsource.cpp
        imagecache.cpp
        ktxencoder.cpp
        visualanalyser.cpp
    QML_FILES
        Visual.qml
    LIBRARIES
        Qt::Quick
        Qt::Multimedia
        Qt::Concurrent
        caelestia::caelestia
        rgbcx
)
