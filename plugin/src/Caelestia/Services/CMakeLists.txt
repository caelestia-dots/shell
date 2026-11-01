qml_module(caelestia-services
    URI Caelestia.Services
    SOURCES
        service.cpp
        serviceref.cpp
        beattracker.cpp
        audiocollector.cpp
        audioprovider.cpp
        cavaprovider.cpp
        tickingservice.cpp
        sensorslib.cpp
        cpu.cpp
        gpu.cpp
        nvml.cpp
        memory.cpp
        diskinfo.cpp
        storage.cpp
        lyriccandidate.cpp
        lyrics.cpp
        sessionmanager.cpp
        networkusage.cpp
        networkdbus.cpp
        hyprdevices.cpp
        hyprextras.cpp
        ddc.cpp
        materialscheme.cpp
    LIBRARIES
        Qt::Concurrent
        Qt::DBus
        Qt::Network
        PkgConfig::Pipewire
        PkgConfig::Aubio
        PkgConfig::Cava
        Sensors::Sensors
        caelestia-util
        caelestia-core
        caelestia-config
        caelestia-material
    DEPENDENCIES
        Caelestia
        Caelestia.Config
)

# DDC/CI brightness uses libddcutil when it's installed; without it the shell runs the ddcutil
# command instead (see services/Brightness.qml)
if(Ddcutil_FOUND)
    target_compile_definitions(caelestia-services PRIVATE CAELESTIA_HAS_DDCUTIL)
    target_link_libraries(caelestia-services PRIVATE PkgConfig::Ddcutil)
endif()
