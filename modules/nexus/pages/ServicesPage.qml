import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Lyrics backends, ordered to match LyricsBackend::Backend (Auto, Local, LRCLIB, NetEase)
    readonly property list<MenuItem> lyricsItems: [
        MenuItem {
            text: qsTr("Auto")
        },
        MenuItem {
            text: "Local"
        },
        MenuItem {
            text: "LRCLIB"
        },
        MenuItem {
            text: "NetEase"
        }
    ]

    // GPU options + the config string each maps to (see Gpu::parseType)
    readonly property list<MenuItem> gpuItems: [
        MenuItem {
            text: qsTr("Auto")
        },
        MenuItem {
            text: "NVIDIA"
        },
        MenuItem {
            text: qsTr("Generic")
        },
        MenuItem {
            text: qsTr("None")
        }
    ]
    readonly property list<string> gpuValues: ["", "NVIDIA", "GENERIC", "None"]
    readonly property list<MenuItem> batteryIndicatorItems: [
        MenuItem {
            text: qsTr("Icon only")
        },
        MenuItem {
            text: qsTr("Text only")
        },
        MenuItem {
            text: qsTr("Icon + text")
        },
        MenuItem {
            text: qsTr("Disabled")
        }
    ]
    readonly property list<int> batteryIndicatorValues: [0, 1, 2, 3]
    readonly property list<MenuItem> indicatorStyleItems: [
        MenuItem {
            text: qsTr("System tray")
        },
        MenuItem {
            text: qsTr("Panel button")
        },
        MenuItem {
            text: qsTr("Compact badge")
        }
    ]
    readonly property list<int> indicatorStyleValues: [0, 1, 2]
    readonly property list<MenuItem> hideIndicatorItems: [
        MenuItem {
            text: qsTr("Always show")
        },
        MenuItem {
            text: qsTr("Hide when visible")
        },
        MenuItem {
            text: qsTr("Only connected")
        }
    ]
    readonly property list<int> hideIndicatorValues: [0, 1, 2]
    readonly property list<MenuItem> batteryLevelIndicatorItems: [
        MenuItem {
            text: qsTr("Bar")
        },
        MenuItem {
            text: qsTr("Dots")
        },
        MenuItem {
            text: qsTr("None")
        }
    ]
    readonly property list<int> batteryLevelIndicatorValues: [0, 1, 2]
    readonly property list<MenuItem> batteryPaletteItems: [
        MenuItem {
            text: qsTr("Adaptive")
        },
        MenuItem {
            text: qsTr("Accent")
        },
        MenuItem {
            text: qsTr("Custom")
        }
    ]
    readonly property list<int> batteryPaletteValues: [0, 1, 2]

    function batteryIndicatorIndexFromState(): int {
        if (!GlobalConfig.services)
            return 2;
        const iconEnabled = Boolean(GlobalConfig.services.bluetoothBatteryIcon);
        const textEnabled = Boolean(GlobalConfig.services.bluetoothBatteryText);
        if (!iconEnabled && !textEnabled)
            return 3;
        if (iconEnabled && !textEnabled)
            return 0;
        if (!iconEnabled && textEnabled)
            return 1;
        return 2;
    }

    function syncBatteryIndicatorType(): void {
        if (!GlobalConfig.services)
            return;
        const idx = batteryIndicatorIndexFromState();
        const safeIndex = Number.isFinite(idx) ? idx : 2;
        GlobalConfig.services.bluetoothBatteryIndicatorType = batteryIndicatorValues[safeIndex];
    }

    function batteryIndicatorModeForButtonIndex(idx: int): void {
        if (!GlobalConfig.services)
            return;
        const safeIdx = Number.isFinite(idx) ? idx : 2;
        const mode = batteryIndicatorValues[safeIdx] ?? 2;
        const showIcon = mode === 0 || mode === 2;
        const showText = mode === 1 || mode === 2;
        GlobalConfig.services.bluetoothBatteryIcon = showIcon;
        GlobalConfig.services.bluetoothBatteryText = showText;
        GlobalConfig.services.bluetoothBatteryIndicatorType = mode;
    }

    function gpuKeyToIndex(key: string): int {
        const u = (key ?? "").trim().toUpperCase();
        if (u === "")
            return 0; // Auto
        if (u === "NVIDIA")
            return 1;
        if (u === "GENERIC")
            return 2;
        return 3; // None
    }

    title: qsTr("Services")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Detected running players, used as default-player options
        Variants {
            id: playerVariants

            model: [...new Set(Players.list.map(p => Players.getIdentity(p)).filter(id => id))]

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === GlobalConfig.services.defaultPlayer ? "check" : ""
                activeIcon: "music_note"
            }
        }

        // Bluetooth
        SectionHeader {
            first: true
            text: qsTr("Bluetooth")
        }

        ToggleRow {
            first: true
            text: qsTr("Bluetooth battery support")
            subtext: qsTr("Enable Bluetooth battery indicators and quick-menu status")
            checked: Boolean(GlobalConfig.services && (GlobalConfig.services.bluetoothBatteryIcon || GlobalConfig.services.bluetoothBatteryText || GlobalConfig.services.bluetoothBatteryRing))
            onToggled: {
                const enabled = Boolean(checked);
                if (GlobalConfig.services) {
                    GlobalConfig.services.bluetoothBatteryIcon = enabled;
                    GlobalConfig.services.bluetoothBatteryText = enabled && Boolean(GlobalConfig.services.bluetoothBatteryText);
                    GlobalConfig.services.bluetoothBatteryRing = enabled;
                }
            }
        }

        ToggleRow {
            text: qsTr("Show battery icon")
            subtext: qsTr("Display the Bluetooth battery icon in the quick menu")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryIcon)
            onToggled: {
                if (!GlobalConfig.services)
                    return;
                GlobalConfig.services.bluetoothBatteryIcon = checked;
                root.syncBatteryIndicatorType();
            }
        }

        ToggleRow {
            text: qsTr("Show battery text")
            subtext: qsTr("Display the battery percentage beside the Bluetooth icon")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryText)
            onToggled: {
                if (!GlobalConfig.services)
                    return;
                GlobalConfig.services.bluetoothBatteryText = checked;
                root.syncBatteryIndicatorType();
            }
        }

        SelectRow {
            label: qsTr("Battery indicator style")
            subtext: qsTr("Choose how the Bluetooth battery is shown")
            menuItems: root.batteryIndicatorItems
            active: {
                const mode = GlobalConfig.services ? GlobalConfig.services.bluetoothBatteryIndicatorType : undefined;
                const idx = Number.isFinite(mode)
                    ? root.batteryIndicatorValues.indexOf(mode)
                    : 2;
                return root.batteryIndicatorItems[Math.max(0, Math.min(root.batteryIndicatorItems.length - 1, idx))];
            }
            onSelected: item => {
                if (!GlobalConfig.services)
                    return;
                const idx = root.batteryIndicatorItems.indexOf(item);
                if (idx >= 0)
                    root.batteryIndicatorModeForButtonIndex(idx);
            }
        }

        SelectRow {
            label: qsTr("Battery level indicator")
            subtext: qsTr("Choose the BBM-style level glyph used inside the battery icon")
            menuItems: root.batteryLevelIndicatorItems
            active: {
                const mode = GlobalConfig.services ? GlobalConfig.services.bluetoothBatteryLevelIndicatorType : 0;
                const idx = Number.isFinite(mode) ? root.batteryLevelIndicatorValues.indexOf(mode) : 0;
                return root.batteryLevelIndicatorItems[Math.max(0, Math.min(root.batteryLevelIndicatorItems.length - 1, idx))];
            }
            onSelected: item => {
                if (!GlobalConfig.services)
                    return;
                const idx = root.batteryLevelIndicatorItems.indexOf(item);
                if (idx >= 0)
                    GlobalConfig.services.bluetoothBatteryLevelIndicatorType = root.batteryLevelIndicatorValues[idx];
            }
        }

        ToggleRow {
            text: qsTr("Swap icon and text")
            subtext: qsTr("Place the battery icon before the percentage text")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatterySwapIconText)
            enabled: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryIcon && GlobalConfig.services.bluetoothBatteryText)
            onToggled: {
                if (GlobalConfig.services)
                    GlobalConfig.services.bluetoothBatterySwapIconText = checked;
            }
        }

        ToggleRow {
            text: qsTr("Show battery ring")
            subtext: qsTr("Display the circular battery indicator around connected devices")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryRing)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryRing = checked
        }

        ToggleRow {
            text: qsTr("Open battery popup in quick settings")
            subtext: qsTr("Show the Bluetooth battery details in a nested popup instead of inline rows")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryPopupInQuickSettings)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryPopupInQuickSettings = checked
        }

        ToggleRow {
            text: qsTr("Sort devices by recent use")
            subtext: qsTr("Keep connected or recently used devices at the top of the list")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatterySortByHistory)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatterySortByHistory = checked
        }

        SelectRow {
            label: qsTr("Indicator visibility")
            subtext: qsTr("Choose when the Bluetooth indicator should be hidden")
            menuItems: root.hideIndicatorItems
            active: {
                const mode = GlobalConfig.services ? GlobalConfig.services.bluetoothBatteryHideIndicatorMode : 0;
                const idx = Number.isFinite(mode) ? root.hideIndicatorValues.indexOf(mode) : 0;
                return root.hideIndicatorItems[Math.max(0, Math.min(root.hideIndicatorItems.length - 1, idx))];
            }
            onSelected: item => {
                if (!GlobalConfig.services)
                    return;
                const idx = root.hideIndicatorItems.indexOf(item);
                if (idx >= 0)
                    GlobalConfig.services.bluetoothBatteryHideIndicatorMode = root.hideIndicatorValues[idx];
            }
        }

        SelectRow {
            label: qsTr("Indicator placement")
            subtext: qsTr("Choose where the Bluetooth battery indicator appears")
            menuItems: root.indicatorStyleItems
            active: {
                const mode = GlobalConfig.services ? GlobalConfig.services.bluetoothBatteryIndicatorStyle : 1;
                const idx = Number.isFinite(mode) ? root.indicatorStyleValues.indexOf(mode) : 1;
                return root.indicatorStyleItems[Math.max(0, Math.min(root.indicatorStyleItems.length - 1, idx))];
            }
            onSelected: item => {
                if (!GlobalConfig.services)
                    return;
                const idx = root.indicatorStyleItems.indexOf(item);
                if (idx >= 0)
                    GlobalConfig.services.bluetoothBatteryIndicatorStyle = root.indicatorStyleValues[idx];
            }
        }

        ToggleRow {
            text: qsTr("Use multi-indicator mode")
            subtext: qsTr("Show each device battery as a separate indicator when multiple devices are connected")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryMultiIndicator)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryMultiIndicator = checked
        }

        ToggleRow {
            text: qsTr("Use hover mode")
            subtext: qsTr("Only reveal the extended battery view when the pointer hovers over the indicator")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryHoverMode)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryHoverMode = checked
        }

        StepperRow {
            label: qsTr("Hover delay")
            subtext: qsTr("Delay before the hover battery popup is shown (ms)")
            value: GlobalConfig.services ? GlobalConfig.services.bluetoothBatteryHoverDelay : 1000
            from: 250
            to: 5000
            stepSize: 50
            onMoved: v => {
                if (GlobalConfig.services)
                    GlobalConfig.services.bluetoothBatteryHoverDelay = Math.round(v);
            }
        }

        ToggleRow {
            text: qsTr("Show battery tooltips")
            subtext: qsTr("Display the device battery and status when hovering over the Bluetooth icon")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryTooltips)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryTooltips = checked
        }

        ToggleRow {
            text: qsTr("Use per-device defaults")
            subtext: qsTr("Let each Bluetooth device keep its own preferred battery display and behaviour")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryPerDeviceDefaults)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryPerDeviceDefaults = checked
        }

        ToggleRow {
            text: qsTr("Enable UPower device support")
            subtext: qsTr("Include extra battery-aware devices that expose power data through UPower")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryUpowerSupport)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryUpowerSupport = checked
        }

        ToggleRow {
            text: qsTr("Use custom battery colours")
            subtext: qsTr("Apply a custom per-bucket battery palette instead of the default adaptive colours")
            checked: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryUseCustomColors)
            onToggled: if (GlobalConfig.services) GlobalConfig.services.bluetoothBatteryUseCustomColors = checked
        }

        SelectRow {
            label: qsTr("Battery colour scheme")
            subtext: qsTr("Choose which battery colour palette is used for device percentages")
            menuItems: root.batteryPaletteItems
            active: {
                const mode = GlobalConfig.services ? GlobalConfig.services.bluetoothBatteryColorScheme : 0;
                const idx = Number.isFinite(mode) ? root.batteryPaletteValues.indexOf(mode) : 0;
                return root.batteryPaletteItems[Math.max(0, Math.min(root.batteryPaletteItems.length - 1, idx))];
            }
            onSelected: item => {
                if (!GlobalConfig.services)
                    return;
                const idx = root.batteryPaletteItems.indexOf(item);
                if (idx >= 0)
                    GlobalConfig.services.bluetoothBatteryColorScheme = root.batteryPaletteValues[idx];
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            visible: Boolean(GlobalConfig.services && GlobalConfig.services.bluetoothBatteryUseCustomColors)

            Repeater {
                model: 10

                Rectangle {
                    width: 22
                    height: 22
                    radius: 6
                    border.width: 1
                    border.color: Colours.palette.m3outline
                    color: (GlobalConfig.services && GlobalConfig.services.bluetoothBatteryColors && GlobalConfig.services.bluetoothBatteryColors[index]) || "#4ade80"

                    StateLayer {
                        anchors.fill: parent
                        onClicked: {
                            if (!GlobalConfig.services)
                                return;
                            const list = GlobalConfig.services.bluetoothBatteryColors.slice();
                            colorDialog.bucketIndex = index;
                            colorDialog.selectedColor = list[index] || "#4ade80";
                            colorDialog.open();
                        }
                    }
                }
            }
        }

        ColorDialog {
            id: colorDialog
            property int bucketIndex: 0
            title: qsTr("Choose battery colour")
            onAccepted: {
                if (!GlobalConfig.services)
                    return;
                const list = GlobalConfig.services.bluetoothBatteryColors.slice();
                list[colorDialog.bucketIndex] = colorDialog.color.toString().toUpperCase();
                GlobalConfig.services.bluetoothBatteryColors = list;
            }
        }

        NavRow {
            first: true
            last: true
            icon: "device_hub"
            text: qsTr("Manage device defaults")
            subtext: qsTr("Configure per-device icon, quick menu and indicator behaviour")
            onClicked: root.nState.openSubPage(2)
        }

        // Notifications
        SectionHeader {
            text: qsTr("Notifications")
        }

        NavRow {
            first: true
            last: true
            icon: "notifications"
            text: qsTr("Notifications")
            subtext: qsTr("Notifications, toasts, timeouts")
            onClicked: root.nState.openSubPage(1)
        }

        // Polling
        SectionHeader {
            text: qsTr("Polling")
        }

        StepperRow {
            first: true
            label: qsTr("Media refresh")
            subtext: qsTr("How often the media position updates (ms)")
            value: GlobalConfig.dashboard.mediaUpdateInterval
            from: 100
            to: 2000
            stepSize: 50
            onMoved: v => GlobalConfig.dashboard.mediaUpdateInterval = v
        }

        StepperRow {
            label: qsTr("System stats refresh")
            subtext: qsTr("CPU, memory and GPU update interval (seconds)")
            value: GlobalConfig.dashboard.resourceUpdateInterval / 1000
            from: 0.5
            to: 10
            stepSize: 0.5
            onMoved: v => GlobalConfig.dashboard.resourceUpdateInterval = Math.round(v * 1000)
        }

        StepperRow {
            last: true
            label: qsTr("Wi-Fi rescan")
            subtext: qsTr("How often available networks are rescanned (seconds)")
            value: GlobalConfig.nexus.networkRescanInterval / 1000
            from: 5
            to: 120
            stepSize: 5
            onMoved: v => GlobalConfig.nexus.networkRescanInterval = Math.round(v * 1000)
        }

        // Media & lyrics
        SectionHeader {
            text: qsTr("Media & lyrics")
        }

        SelectRow {
            first: true
            label: qsTr("Lyrics backend")
            subtext: qsTr("Source used to fetch synced lyrics")
            menuItems: root.lyricsItems
            active: root.lyricsItems[Lyrics.preferredBackend] ?? root.lyricsItems[0]
            onSelected: item => Lyrics.preferredBackend = root.lyricsItems.indexOf(item)
        }

        SelectRow {
            last: true
            label: qsTr("Default player")
            subtext: qsTr("Preferred media player when several are open")
            menuItems: playerVariants.instances
            active: menuItems.find(i => i.text === GlobalConfig.services.defaultPlayer) ?? null
            fallbackIcon: "music_note"
            fallbackText: GlobalConfig.services.defaultPlayer || qsTr("Auto")
            onSelected: item => GlobalConfig.services.defaultPlayer = item.text
        }

        // Input increments
        SectionHeader {
            text: qsTr("Input increments")
        }

        StepperRow {
            first: true
            label: qsTr("Volume step")
            subtext: qsTr("Amount the volume changes per scroll (%)")
            value: Math.round(GlobalConfig.services.audioIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.audioIncrement = v / 100
        }

        StepperRow {
            label: qsTr("Brightness step")
            subtext: qsTr("Amount the brightness changes per scroll (%)")
            value: Math.round(GlobalConfig.services.brightnessIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.brightnessIncrement = v / 100
        }

        StepperRow {
            last: true
            label: qsTr("Max volume")
            subtext: qsTr("Upper limit for output volume (%)")
            value: Math.round(GlobalConfig.services.maxVolume * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.services.maxVolume = v / 100
        }

        // Service tuning
        SectionHeader {
            text: qsTr("Service tuning")
        }

        StepperRow {
            first: true
            label: qsTr("Visualiser bars")
            subtext: qsTr("Number of bars in the audio visualisers")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }

        ToggleRow {
            text: qsTr("Smart colour scheme")
            subtext: qsTr("Derive theme mode and variant from the wallpaper")
            checked: GlobalConfig.services.smartScheme
            onToggled: GlobalConfig.services.smartScheme = checked
        }

        SelectRow {
            last: true
            label: qsTr("GPU")
            subtext: Gpu.name ? qsTr("Monitoring: %1").arg(Gpu.name) : qsTr("Override for GPU type")
            menuOnTop: true
            menuItems: root.gpuItems
            active: root.gpuItems[root.gpuKeyToIndex(GlobalConfig.services.gpuType)]
            onSelected: item => GlobalConfig.services.gpuType = root.gpuValues[root.gpuItems.indexOf(item)]
        }
    }
}
