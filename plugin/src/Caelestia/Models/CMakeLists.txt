qml_module(caelestia-models
    URI Caelestia.Models
    INCLUDE_PREFIX models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
    LIBRARIES
        Qt::Gui
        Qt::Multimedia
        Qt::Concurrent
        Qt::Sql
)
