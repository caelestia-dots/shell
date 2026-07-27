qml_module(caelestia-plugins
    URI Caelestia.Plugins
    SOURCES
        plugins.cpp
        pluginmanifest.cpp
        entrypoint.cpp
        entrypointloader.cpp
        settingsobject.cpp
        settingmeta.cpp
    LIBRARIES
        Qt::Quick
)

# Bake the shell version in so plugin requirements can be checked against it
target_compile_definitions(caelestia-plugins PRIVATE CAELESTIA_VERSION="${VERSION}")
