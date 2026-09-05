qml_module(caelestia-core
    URI Caelestia
    INCLUDE_PREFIX core
    SOURCES
        cutils.cpp
        qalculator.cpp
        requests.cpp
        toaster.cpp
        circularbuffer.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        PkgConfig::Qalculate
        caelestia-util
)

# Bake the shell version and git revision in so CUtils can expose them without
# spawning a process; the revision also invalidates the settings index cache.
target_compile_definitions(caelestia-core PRIVATE
    CAELESTIA_VERSION="${VERSION}"
    GIT_REVISION="${GIT_REVISION}"
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
