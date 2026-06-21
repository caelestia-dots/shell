qml_module(caelestia
    URI Caelestia
    PLUGIN_SOURCE plugin.cpp
    SOURCES
        cutils.hpp cutils.cpp
        qalculator.hpp qalculator.cpp
        appdb.hpp appdb.cpp
        requests.hpp requests.cpp
        toaster.hpp toaster.cpp
        imageanalyser.hpp imageanalyser.cpp
        translationloader.hpp translationloader.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Sql
        PkgConfig::Qalculate
)

# Bake the shell version in so CUtils can expose it without spawning a process
target_compile_definitions(caelestia PRIVATE CAELESTIA_VERSION="${VERSION}")

# Where to look for installed translations at runtime.
target_compile_definitions(caelestia PRIVATE
    CAELESTIA_TRANSLATIONS_DIR="/${INSTALL_QSCONFDIR}/translations"
)

add_subdirectory(Components)
add_subdirectory(Config)
add_subdirectory(Internal)
add_subdirectory(Models)
add_subdirectory(Services)
add_subdirectory(Blobs)
add_subdirectory(Images)
