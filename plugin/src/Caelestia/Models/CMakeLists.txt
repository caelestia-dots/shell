qml_module(caelestia-models
    URI Caelestia.Models
    INCLUDE_PREFIX models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
        notifdata.cpp
        notifstore.cpp
    LIBRARIES
        caelestia-config
        caelestia::caelestia
        Qt::Gui
        Qt::Quick
        Qt::Multimedia
        Qt::Concurrent
        Qt::Sql
)
