qml_module(caelestia-core
    URI Caelestia
    INCLUDE_PREFIX core
    PLUGIN_SOURCE plugin.cpp
    SOURCES
        cutils.cpp
        qalculator.cpp
        requests.cpp
        toaster.cpp
        circularbuffer.cpp
        translationloader.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        PkgConfig::Qalculate
        caelestia-util
)

# Bake the shell version in so CUtils can expose it without spawning a process
target_compile_definitions(caelestia-core PRIVATE CAELESTIA_VERSION="${VERSION}")

# Where to look for installed translations at runtime.
target_compile_definitions(caelestia-core PRIVATE
    CAELESTIA_TRANSLATIONS_DIR="/${INSTALL_QSCONFDIR}/translations"
)

# Node macros expand to Q_OBJECT, automoc can't see it otherwise
list(APPEND CMAKE_AUTOMOC_MACRO_NAMES
    SETTINGS_NODE SETTINGS_NODE_NO_CTOR SETTINGS_LIST_TYPE
    CONFIG_NODE CONFIG_NODE_NO_CTOR CONFIG_LIST_TYPE
)

add_subdirectory(Settings)
add_subdirectory(Components)
add_subdirectory(Config)
add_subdirectory(Models)
add_subdirectory(Services)
add_subdirectory(Blobs)
add_subdirectory(Images)
