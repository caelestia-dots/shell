qml_module(caelestia-models
    URI Caelestia.Models
    INCLUDE_PREFIX models
    SOURCES
        filesystemmodel.cpp
        filtermodel.cpp
        appdb.cpp
        notifdata.cpp
        notifgroup.cpp
        notifgroupindex.cpp
        notifpopups.cpp
        notifstore.cpp
    LIBRARIES
        caelestia-util
        caelestia-config
        caelestia::caelestia
        Qt::Gui
        Qt::Quick
        Qt::QmlModels
        Qt::Multimedia
        Qt::Concurrent
        Qt::Sql
)
