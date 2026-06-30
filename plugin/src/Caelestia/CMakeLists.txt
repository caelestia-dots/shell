# The settings index is generated into the build dir; map it to a stable resource
# path (qrc:/qt/qml/Caelestia/settings-index.json) regardless of its source path.
set_source_files_properties("${SETTINGS_INDEX_JSON}" PROPERTIES
    QT_RESOURCE_ALIAS "settings-index.json")

qml_module(caelestia-core
    URI Caelestia
    SOURCES
        cutils.cpp
        qalculator.cpp
        appdb.cpp
        requests.cpp
        toaster.cpp
        imageanalyser.cpp
    RESOURCES
        "${SETTINGS_INDEX_JSON}"
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Sql
        PkgConfig::Qalculate
)

# Bake the shell version in so CUtils can expose it without spawning a process
target_compile_definitions(caelestia-core PRIVATE CAELESTIA_VERSION="${VERSION}")

add_subdirectory(Components)
add_subdirectory(Config)
add_subdirectory(Internal)
add_subdirectory(Models)
add_subdirectory(Services)
add_subdirectory(Blobs)
add_subdirectory(Images)
