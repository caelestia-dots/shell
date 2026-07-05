qml_module(caelestia-core
    URI Caelestia
    SOURCES
        cutils.cpp
        qalculator.cpp
        appdb.cpp
        requests.cpp
        toaster.cpp
        imageanalyser.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Sql
        PkgConfig::Qalculate
)

# Bake the shell version in so CUtils can expose it without spawning a process
target_compile_definitions(caelestia-core PRIVATE CAELESTIA_VERSION="${VERSION}")

# Translations install path for the translator loader
get_filename_component(_caelestia_translations_dir "${CMAKE_INSTALL_PREFIX}/${INSTALL_TRANSLATIONSDIR}" ABSOLUTE)
target_compile_definitions(caelestia-core PRIVATE CAELESTIA_TRANSLATIONS_DIR="${_caelestia_translations_dir}")

add_subdirectory(Components)
add_subdirectory(Config)
add_subdirectory(Internal)
add_subdirectory(Models)
add_subdirectory(Services)
add_subdirectory(Blobs)
add_subdirectory(Images)
