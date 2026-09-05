import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        UdevService;
        Weather.reload();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
