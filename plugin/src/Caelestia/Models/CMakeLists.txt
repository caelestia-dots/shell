qml_module(caelestia-models
    URI Caelestia.Models
    INCLUDE_PREFIX models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
        notifdata.cpp
    LIBRARIES
        caelestia-config
        Qt::Gui
        Qt::Multimedia
        Qt::Concurrent
        Qt::Sql
)
