qml_module(caelestia
    URI Caelestia
    SOURCES
        cutils.hpp cutils.cpp
        qalculator.hpp qalculator.cpp
        appdb.hpp appdb.cpp
        requests.hpp requests.cpp
        toaster.hpp toaster.cpp
        imageanalyser.hpp imageanalyser.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Sql
        PkgConfig::Qalculate
)
