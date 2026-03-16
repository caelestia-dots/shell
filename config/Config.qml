pragma Singleton

import qs.utils
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias appearance: adapter.appearance
    property alias general: adapter.general
    property alias background: adapter.background
    property alias bar: adapter.bar
    property alias border: adapter.border
    property alias dashboard: adapter.dashboard
    property alias controlCenter: adapter.controlCenter
    property alias launcher: adapter.launcher
    property alias notifs: adapter.notifs
    property alias osd: adapter.osd
    property alias session: adapter.session
    property alias winfo: adapter.winfo
    property alias lock: adapter.lock
    property alias utilities: adapter.utilities
    property alias sidebar: adapter.sidebar
    property alias services: adapter.services
    property alias paths: adapter.paths

    property bool recentlySaved: false

    // Public save function - call this to persist config changes
    function save(): void {
        saveTimer.restart();
        recentlySaved = true;
        recentSaveCooldown.restart();
    }

    // Helper function to serialize the config object
    function serializeConfig(): var {
        return {
            appearance: serializeAppearance(),
            general: serializeGeneral(),
            background: serializeBackground(),
            bar: serializeBar(),
            border: serializeBorder(),
            dashboard: serializeDashboard(),
            controlCenter: serializeControlCenter(),
            launcher: serializeLauncher(),
            notifs: serializeNotifs(),
            osd: serializeOsd(),
            session: serializeSession(),
            winfo: serializeWinfo(),
            lock: serializeLock(),
            utilities: serializeUtilities(),
            sidebar: serializeSidebar(),
            services: serializeServices(),
            paths: serializePaths()
        };
    }

    function serializeAppearance(): var {
        return {
            rounding: {
                scale: appearance.rounding.scale
            },
            spacing: {
                scale: appearance.spacing.scale
            },
            padding: {
                scale: appearance.padding.scale
            },
            font: {
                family: {
                    sans: appearance.font.family.sans,
                    mono: appearance.font.family.mono,
                    material: appearance.font.family.material,
                    clock: appearance.font.family.clock
                },
                size: {
                    scale: appearance.font.size.scale
                }
            },
            anim: {
                mediaGifSpeedAdjustment: 300,
                sessionGifSpeed: 0.7,
                durations: {
                    scale: appearance.anim.durations.scale
                }
            },
            transparency: {
                enabled: appearance.transparency.enabled,
                base: appearance.transparency.base,
                layers: appearance.transparency.layers
            }
        };
    }

    function serializeGeneral(): var {
        return {
            logo: general.logo,
            excludedScreens: general.excludedScreens,
            apps: {
                terminal: general.apps.terminal,
                audio: general.apps.audio,
                playback: general.apps.playback,
                explorer: general.apps.explorer
            },
            idle: {
                lockBeforeSleep: general.idle.lockBeforeSleep,
                inhibitWhenAudio: general.idle.inhibitWhenAudio,
                timeouts: general.idle.timeouts
            },
            battery: {
                warnLevels: general.battery.warnLevels,
                criticalLevel: general.battery.criticalLevel
            }
        };
    }

    function serializeBackground(): var {
        return {
            enabled: background.enabled,
            wallpaperEnabled: background.wallpaperEnabled,
            desktopClock: {
                enabled: background.desktopClock.enabled,
                scale: background.desktopClock.scale,
                position: background.desktopClock.position,
                invertColors: background.desktopClock.invertColors,
                background: {
                    enabled: background.desktopClock.background.enabled,
                    opacity: background.desktopClock.background.opacity,
                    blur: background.desktopClock.background.blur
                },
                shadow: {
                    enabled: background.desktopClock.shadow.enabled,
                    opacity: background.desktopClock.shadow.opacity,
                    blur: background.desktopClock.shadow.blur
                }
            },
            visualiser: {
                enabled: background.visualiser.enabled,
                autoHide: background.visualiser.autoHide,
                blur: background.visualiser.blur,
                rounding: background.visualiser.rounding,
                spacing: background.visualiser.spacing
            }
        };
    }

    function serializeBar(): var {
        return {
            persistent: bar.persistent,
            showOnHover: bar.showOnHover,
            dragThreshold: bar.dragThreshold,
            scrollActions: {
                workspaces: bar.scrollActions.workspaces,
                volume: bar.scrollActions.volume,
                brightness: bar.scrollActions.brightness
            },
            popouts: {
                activeWindow: bar.popouts.activeWindow,
                tray: bar.popouts.tray,
                statusIcons: bar.popouts.statusIcons
            },
            workspaces: {
                shown: bar.workspaces.shown,
                activeIndicator: bar.workspaces.activeIndicator,
                occupiedBg: bar.workspaces.occupiedBg,
                showWindows: bar.workspaces.showWindows,
                showWindowsOnSpecialWorkspaces: bar.workspaces.showWindowsOnSpecialWorkspaces,
                maxWindowIcons: bar.workspaces.maxWindowIcons,
                activeTrail: bar.workspaces.activeTrail,
                perMonitorWorkspaces: bar.workspaces.perMonitorWorkspaces,
                label: bar.workspaces.label,
                occupiedLabel: bar.workspaces.occupiedLabel,
                activeLabel: bar.workspaces.activeLabel,
                capitalisation: bar.workspaces.capitalisation,
                specialWorkspaceIcons: bar.workspaces.specialWorkspaceIcons,
                windowIcons: bar.workspaces.windowIcons
            },
            activeWindow: {
                compact: bar.activeWindow.compact,
                inverted: bar.activeWindow.inverted,
                showOnHover: bar.activeWindow.showOnHover
            },
            tray: {
                background: bar.tray.background,
                recolour: bar.tray.recolour,
                compact: bar.tray.compact,
                iconSubs: bar.tray.iconSubs,
                hiddenIcons: bar.tray.hiddenIcons
            },
            status: {
                showAudio: bar.status.showAudio,
                showMicrophone: bar.status.showMicrophone,
                showKbLayout: bar.status.showKbLayout,
                showNetwork: bar.status.showNetwork,
                showWifi: bar.status.showWifi,
                showBluetooth: bar.status.showBluetooth,
                showBattery: bar.status.showBattery,
                showLockStatus: bar.status.showLockStatus
            },
            clock: {
                showIcon: bar.clock.showIcon
            },
            entries: bar.entries,
            excludedScreens: bar.excludedScreens
        };
    }

    function serializeBorder(): var {
        return {
            thickness: border.thickness,
            rounding: border.rounding
        };
    }

    function serializeDashboard(): var {
        return {
            enabled: dashboard.enabled,
            showOnHover: dashboard.showOnHover,
            mediaUpdateInterval: dashboard.mediaUpdateInterval,
            resourceUpdateInterval: dashboard.resourceUpdateInterval,
            dragThreshold: dashboard.dragThreshold,
            performance: {
                showBattery: dashboard.performance.showBattery,
                showGpu: dashboard.performance.showGpu,
                showCpu: dashboard.performance.showCpu,
                showMemory: dashboard.performance.showMemory,
                showStorage: dashboard.performance.showStorage,
                showNetwork: dashboard.performance.showNetwork
            }
        };
    }

    function serializeControlCenter(): var {
        return {};
    }

    function serializeLauncher(): var {
        return {
            enabled: launcher.enabled,
            showOnHover: launcher.showOnHover,
            maxShown: launcher.maxShown,
            maxWallpapers: launcher.maxWallpapers,
            specialPrefix: launcher.specialPrefix,
            actionPrefix: launcher.actionPrefix,
            enableDangerousActions: launcher.enableDangerousActions,
            dragThreshold: launcher.dragThreshold,
            vimKeybinds: launcher.vimKeybinds,
            favouriteApps: launcher.favouriteApps,
            hiddenApps: launcher.hiddenApps,
            useFuzzy: {
                apps: launcher.useFuzzy.apps,
                actions: launcher.useFuzzy.actions,
                schemes: launcher.useFuzzy.schemes,
                variants: launcher.useFuzzy.variants,
                wallpapers: launcher.useFuzzy.wallpapers
            },
            actions: launcher.actions
        };
    }

    function serializeNotifs(): var {
        return {
            expire: notifs.expire,
            defaultExpireTimeout: notifs.defaultExpireTimeout,
            clearThreshold: notifs.clearThreshold,
            expandThreshold: notifs.expandThreshold,
            actionOnClick: notifs.actionOnClick,
            groupPreviewNum: notifs.groupPreviewNum
        };
    }

    function serializeOsd(): var {
        return {
            enabled: osd.enabled,
            hideDelay: osd.hideDelay,
            enableBrightness: osd.enableBrightness,
            enableMicrophone: osd.enableMicrophone
        };
    }

    function serializeSession(): var {
        return {
            enabled: session.enabled,
            dragThreshold: session.dragThreshold,
            vimKeybinds: session.vimKeybinds,
            icons: {
                logout: session.icons.logout,
                shutdown: session.icons.shutdown,
                hibernate: session.icons.hibernate,
                reboot: session.icons.reboot
            },
            commands: {
                logout: session.commands.logout,
                shutdown: session.commands.shutdown,
                hibernate: session.commands.hibernate,
                reboot: session.commands.reboot
            }
        };
    }

    function serializeWinfo(): var {
        return {};
    }

    function serializeLock(): var {
        return {
            recolourLogo: lock.recolourLogo,
            enableFprint: lock.enableFprint,
            maxFprintTries: lock.maxFprintTries,
            hideNotifs: lock.hideNotifs
        };
    }

    function serializeUtilities(): var {
        return {
            enabled: utilities.enabled,
            maxToasts: utilities.maxToasts,
            toasts: {
                configLoaded: utilities.toasts.configLoaded,
                chargingChanged: utilities.toasts.chargingChanged,
                gameModeChanged: utilities.toasts.gameModeChanged,
                dndChanged: utilities.toasts.dndChanged,
                audioOutputChanged: utilities.toasts.audioOutputChanged,
                audioInputChanged: utilities.toasts.audioInputChanged,
                capsLockChanged: utilities.toasts.capsLockChanged,
                numLockChanged: utilities.toasts.numLockChanged,
                kbLayoutChanged: utilities.toasts.kbLayoutChanged,
                vpnChanged: utilities.toasts.vpnChanged,
                nowPlaying: utilities.toasts.nowPlaying
            },
            vpn: {
                enabled: utilities.vpn.enabled,
                provider: utilities.vpn.provider
            },
            quickToggles: utilities.quickToggles
        };
    }

    function serializeSidebar(): var {
        return {
            enabled: sidebar.enabled,
            dragThreshold: sidebar.dragThreshold
        };
    }

    function serializeServices(): var {
        return {
            weatherLocation: services.weatherLocation,
            useFahrenheit: services.useFahrenheit,
            useFahrenheitPerformance: services.useFahrenheitPerformance,
            useTwelveHourClock: services.useTwelveHourClock,
            gpuType: services.gpuType,
            visualiserBars: services.visualiserBars,
            audioIncrement: services.audioIncrement,
            brightnessIncrement: services.brightnessIncrement,
            maxVolume: services.maxVolume,
            smartScheme: services.smartScheme,
            defaultPlayer: services.defaultPlayer,
            playerAliases: services.playerAliases
        };
    }

    function serializePaths(): var {
        return {
            wallpaperDir: paths.wallpaperDir,
            sessionGif: paths.sessionGif,
            mediaGif: paths.mediaGif
        };
    }

    ElapsedTimer {
        id: timer
    }

    Timer {
        id: saveTimer

        interval: 500
        onTriggered: {
            timer.restart();
            try {
                // Parse current config to preserve structure and comments if possible
                let config = {};
                try {
                    config = JSON.parse(fileView.text());
                } catch (e) {
                    // If parsing fails, start with empty object
                    config = {};
                }

                // Update config with current values
                config = root.serializeConfig();

                // Save to file with pretty printing
                fileView.setText(JSON.stringify(config, null, 2));
            } catch (e) {
                Toaster.toast(qsTr("Failed to serialize config"), e.message, "settings_alert", Toast.Error);
            }
        }
    }

    Timer {
        id: recentSaveCooldown

        interval: 2000
        onTriggered: {
            root.recentlySaved = false;
        }
    }

    FileView {
        id: fileView

        path: `${Paths.config}/shell.json`
        watchChanges: true
        onFileChanged: {
            // Prevent reload loop - don't reload if we just saved
            if (!root.recentlySaved) {
                timer.restart();
                reload();
            } else {
                // Self-initiated save - reload without toast
                reload();
            }
        }
        onLoaded: {
            try {
                JSON.parse(text());
                const elapsed = timer.elapsedMs();
                // Only show toast for external changes (not our own saves) and when elapsed time is meaningful
                if (adapter.utilities.toasts.configLoaded && !root.recentlySaved && elapsed > 0) {
                    Toaster.toast(qsTr("Config loaded"), qsTr("Config loaded in %1ms").arg(elapsed), "rule_settings");
                } else if (adapter.utilities.toasts.configLoaded && root.recentlySaved && elapsed > 0) {
                    Toaster.toast(qsTr("Config saved"), qsTr("Config reloaded in %1ms").arg(elapsed), "rule_settings");
                }
            } catch (e) {
                Toaster.toast(qsTr("Failed to load config"), e.message, "settings_alert", Toast.Error);
            }
        }
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                Toaster.toast(qsTr("Failed to read config file"), FileViewError.toString(err), "settings_alert", Toast.Warning);
        }
        onSaveFailed: err => Toaster.toast(qsTr("Failed to save config"), FileViewError.toString(err), "settings_alert", Toast.Error)

        JsonAdapter {
            id: adapter

            property AppearanceConfig appearance: AppearanceConfig {}
            property GeneralConfig general: GeneralConfig {}
            property BackgroundConfig background: BackgroundConfig {}
            property BarConfig bar: BarConfig {}
            property BorderConfig border: BorderConfig {}
            property DashboardConfig dashboard: DashboardConfig {}
            property ControlCenterConfig controlCenter: ControlCenterConfig {}
            property LauncherConfig launcher: LauncherConfig {}
            property NotifsConfig notifs: NotifsConfig {}
            property OsdConfig osd: OsdConfig {}
            property SessionConfig session: SessionConfig {}
            property WInfoConfig winfo: WInfoConfig {}
            property LockConfig lock: LockConfig {}
            property UtilitiesConfig utilities: UtilitiesConfig {}
            property SidebarConfig sidebar: SidebarConfig {}
            property ServiceConfig services: ServiceConfig {}
            property UserPaths paths: UserPaths {}
        }
    }
}
