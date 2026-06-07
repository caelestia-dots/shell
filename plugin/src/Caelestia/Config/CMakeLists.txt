qml_module(caelestia-config
    URI Caelestia.Config
    SOURCES
        config.hpp config.cpp
        configattached.hpp configattached.cpp
        configobject.hpp configobject.cpp
        rootconfig.hpp rootconfig.cpp
        appearanceconfig.hpp appearanceconfig.cpp
        font.hpp font.cpp
        fontbuilder.hpp fontbuilder.cpp
        tokens.hpp tokens.cpp
        tokensattached.hpp tokensattached.cpp
        anim.hpp anim.cpp
        monitorconfigmanager.hpp monitorconfigmanager.cpp
        backgroundconfig.hpp
        barconfig.hpp
        borderconfig.hpp
        dashboardconfig.hpp
        generalconfig.hpp
        launcherconfig.hpp
        lockconfig.hpp
        nexusconfig.hpp
        notifsconfig.hpp
        osdconfig.hpp
        serviceconfig.hpp
        sessionconfig.hpp
        sidebarconfig.hpp
        userpaths.hpp
        utilitiesconfig.hpp
        winfoconfig.hpp
    LIBRARIES
        Qt::Quick
        Qt::QuickControls2
)
