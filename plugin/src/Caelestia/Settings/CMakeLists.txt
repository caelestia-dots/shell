qml_module(caelestia-settings
    URI Caelestia.Settings
    SOURCES
        common.cpp
        schema.cpp
        codecs.cpp
        quarantine.cpp
        node.cpp
        objectnode.cpp
        listnode.cpp
        rootnode.cpp
        settingsfile.cpp
        changebatcher.cpp
    LIBRARIES
        caelestia-util
)

# Expose headers as settings/xxx.hpp
set(settings_include_dir "${CMAKE_CURRENT_BINARY_DIR}/include")
file(MAKE_DIRECTORY "${settings_include_dir}")
file(CREATE_LINK "${CMAKE_CURRENT_SOURCE_DIR}" "${settings_include_dir}/settings" SYMBOLIC)
target_include_directories(caelestia-settings PUBLIC "${settings_include_dir}")
