qml_module(caelestia-services
    URI Caelestia.Services
    SOURCES
        service.hpp service.cpp
        serviceref.hpp serviceref.cpp
        beattracker.hpp beattracker.cpp
        audiocollector.hpp audiocollector.cpp
        audioprovider.hpp audioprovider.cpp
        cavaprovider.hpp cavaprovider.cpp
        tickingservice.hpp tickingservice.cpp
        sensorslib.hpp sensorslib.cpp
        usagefmt.hpp usagefmt.cpp
        cpu.hpp cpu.cpp
        gpu.hpp gpu.cpp
        memory.hpp memory.cpp
        diskinfo.hpp diskinfo.cpp
        storage.hpp storage.cpp
        lyriccandidate.hpp lyriccandidate.cpp
        lyrics.hpp lyrics.cpp
        sessionmanager.cpp
    LIBRARIES
        Qt::DBus
        PkgConfig::Pipewire
        PkgConfig::Aubio
        PkgConfig::Cava
        Sensors::Sensors
        caelestia-core
        caelestia-config
        caelestia-internal
)