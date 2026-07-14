qml_module(caelestia-plugins
    URI Caelestia.Plugins
    SOURCES
        plugins.cpp
        pluginmanifest.cpp
        pluginmanifest.hpp
        entrypoint.cpp
        entrypoint.hpp
        settingsobject.cpp
        settingsobject.hpp
        settingmeta.cpp
        settingmeta.hpp
)

# Bake the shell version in so plugin requirements can be checked against it
target_compile_definitions(caelestia-plugins PRIVATE CAELESTIA_VERSION="${VERSION}")
