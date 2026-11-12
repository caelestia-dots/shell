pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.components
import qs.components.effects
import qs.components.hallownest
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.notch
import qs.modules.notch.pages.home as HomeDetails

NotchPage {
    id: root

    // "" = overview; otherwise the bar popout shown in place: network, bluetooth, audio, battery
    property string detail
    property SystemTrayItem trayItem
    readonly property MprisPlayer player: NotchMedia.player
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
    readonly property real battery: UPower.displayDevice.percentage
    readonly property var btConnected: Bluetooth.devices.values.find(d => d.connected) ?? null

    function open(id: string): void {
        screenState.notchPage = NotchPages.find(id);
    }

    onTrayItemChanged: {
        // the app quit while its menu was open
        if (!trayItem && detail === "tray")
            detail = "";
    }

    implicitWidth: 660
    implicitHeight: detail ? detailView.implicitHeight : overview.implicitHeight

    ColumnLayout {
        id: overview

        anchors.left: parent.left
        anchors.right: parent.right
        visible: !root.detail
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Tile {
                icon: Nmcli.activeEthernet ? "lan" : Nmcli.wifiEnabled ? "wifi" : "wifi_off"
                title: Tr.tr("Wi-Fi")
                subtitle: Nmcli.activeEthernet ? Tr.tr("Ethernet") : !Nmcli.wifiEnabled ? Tr.tr("Off") : Nmcli.active?.ssid ?? Tr.tr("Not connected")
                checked: Nmcli.wifiEnabled
                onToggled: Nmcli.enableWifi(!Nmcli.wifiEnabled)
                onMore: root.detail = "network"
            }

            Tile {
                icon: !Bluetooth.defaultAdapter?.enabled ? "bluetooth_disabled" : root.btConnected ? "bluetooth_connected" : "bluetooth"
                title: Tr.tr("Bluetooth")
                subtitle: !Bluetooth.defaultAdapter?.enabled ? Tr.tr("Off") : root.btConnected?.name ?? Tr.tr("On")
                checked: Bluetooth.defaultAdapter?.enabled ?? false
                accent: Hallownest.lifeblood
                onToggled: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.enabled = !adapter.enabled;
                }
                onMore: root.detail = "bluetooth"
            }

            Tile {
                icon: root.charging ? "battery_charging_full" : root.battery <= 0.2 ? "battery_alert" : "battery_full"
                title: UPower.displayDevice.isLaptopBattery ? `${Math.round(root.battery * 100)}%` : Tr.tr("Power")
                subtitle: root.charging ? Tr.tr("Charging") : PowerProfiles.profile === PowerProfile.PowerSaver ? Tr.tr("Power saver") : PowerProfiles.profile === PowerProfile.Performance ? Tr.tr("Performance") : Tr.tr("Balanced")
                checked: root.charging
                accent: root.battery <= 0.2 && !root.charging ? Hallownest.grimm : Hallownest.unn
                onToggled: root.detail = "battery"
                onMore: root.detail = "battery"
            }
        }

        Panel {
            Layout.fillWidth: true
            implicitHeight: 44

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.medium

                IconButton {
                    icon: Audio.muted ? "volume_off" : Audio.volume < 0.4 ? "volume_down" : "volume_up"
                    colour: Audio.muted ? Hallownest.grimm : Hallownest.soul
                    onClicked: {
                        if (Audio.sink?.audio)
                            Audio.sink.audio.muted = !Audio.muted;
                    }
                }

                HkSlider {
                    Layout.fillWidth: true
                    value: Audio.volume
                    colour: Hallownest.lifeblood
                    onMoved: v => Audio.setVolume(v)
                }

                StyledText {
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(Audio.volume * 100)}%`
                    color: Hallownest.subtext
                    font.family: Hallownest.mono
                    font.pointSize: 9
                }

                IconButton {
                    icon: "tune"
                    onClicked: root.detail = "mixer"
                }

                IconButton {
                    icon: "chevron_right"
                    onClicked: root.detail = "audio"
                }

                Rectangle {
                    implicitWidth: 1
                    implicitHeight: 20
                    color: Hallownest.border
                }

                QuickToggle {
                    icon: Audio.sourceMuted ? "mic_off" : "mic"
                    checked: !Audio.sourceMuted
                    onClicked: {
                        const audio = Audio.source?.audio;
                        if (audio)
                            audio.muted = !audio.muted;
                    }
                }

                QuickToggle {
                    icon: "coffee"
                    checked: RuntimeState.inhibitIdle
                    accent: Hallownest.gold
                    onClicked: RuntimeState.inhibitIdle = !RuntimeState.inhibitIdle
                }

                QuickToggle {
                    icon: "notifications_off"
                    checked: PersistentState.doNotDisturb
                    accent: Hallownest.grimm
                    onClicked: PersistentState.doNotDisturb = !PersistentState.doNotDisturb
                }
            }
        }

        Panel {
            Layout.fillWidth: true
            implicitHeight: 56

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open("media")
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                ClippingRectangle {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 8
                    color: Hallownest.card
                    border.width: 1
                    border.color: Hallownest.border

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Hallownest.steel
                        visible: art.status !== Image.Ready
                    }

                    Image {
                        id: art

                        anchors.fill: parent
                        source: root.player ? Players.getArtUrl(root.player) : ""
                        sourceSize.width: 80
                        sourceSize.height: 80
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.player ? root.player.trackTitle || Tr.tr("Unknown title") : Tr.tr("Nothing playing")
                        color: root.player ? Hallownest.soul : Hallownest.subtext
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !!root.player
                        text: root.player?.trackArtist ?? ""
                        color: Hallownest.subtext
                        font.pointSize: 9
                        elide: Text.ElideRight
                    }
                }

                HkButton {
                    visible: !!root.player
                    icon: root.player?.isPlaying ? "pause" : "play_arrow"
                    filled: true
                    disabled: !(root.player?.canTogglePlaying ?? false)
                    onClicked: root.player?.togglePlaying()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: NotchPages.tools

                HkButton {
                    required property var modelData

                    icon: modelData.icon
                    text: modelData.label
                    onClicked: root.open(modelData.id)
                }
            }

            HkButton {
                icon: "settings"
                text: Tr.tr("Settings")
                onClicked: {
                    root.screenState.notch = false;
                    WindowFactory.create(null, {});
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Repeater {
                model: ScriptModel {
                    values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
                }

                MouseArea {
                    id: trayIcon

                    required property SystemTrayItem modelData

                    implicitWidth: 30
                    implicitHeight: 30
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event?.button === Qt.MiddleButton) {
                            modelData.secondaryActivate();
                        } else if (modelData.hasMenu && (event?.button === Qt.RightButton || modelData.onlyMenu)) {
                            root.trayItem = modelData;
                            root.detail = "tray";
                        } else {
                            modelData.activate();
                        }
                    }

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: 18
                        source: Icons.getTrayIcon(trayIcon.modelData.id, trayIcon.modelData.icon)
                        colour: Hallownest.steel
                        layer.enabled: Config.bar.tray.recolour
                    }
                }
            }

            HkButton {
                visible: !Recorder.running
                icon: "videocam"
                onClicked: Recorder.start()
            }

            HkButton {
                visible: !Recorder.running
                icon: "crop_free"
                onClicked: {
                    // slurp needs the notch out of the way to pick the region
                    root.screenState.notch = false;
                    Recorder.start(["-r"]);
                }
            }

            HkButton {
                visible: Recorder.running
                icon: "stop_circle"
                text: Recorder.elapsedText()
                accent: Hallownest.grimm
                tinted: true
                onClicked: Recorder.stop()
            }

            HkButton {
                icon: "power_settings_new"
                accent: Hallownest.grimm
                tinted: true
                onClicked: {
                    root.screenState.notch = false;
                    root.screenState.session = true;
                }
            }
        }
    }

    ColumnLayout {
        id: detailView

        anchors.left: parent.left
        anchors.right: parent.right
        visible: !!root.detail
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            HkButton {
                icon: "arrow_back"
                onClicked: root.detail = ""
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.spacing.extraSmall
                text: ({
                        network: Tr.tr("Network"),
                        bluetooth: Tr.tr("Bluetooth"),
                        audio: Tr.tr("Sound"),
                        mixer: Tr.tr("App volumes"),
                        battery: Tr.tr("Power"),
                        tray: root.trayItem?.tooltipTitle || root.trayItem?.title || root.trayItem?.id || ""
                    })[root.detail] ?? ""
                color: Hallownest.soul
                font.family: Hallownest.serif
                font.pointSize: 12
                font.weight: Font.Bold
            }

            HkButton {
                visible: root.detail !== "battery" && root.detail !== "tray"
                icon: "settings"
                text: Tr.tr("Open settings")
                onClicked: {
                    root.screenState.notch = false;
                    WindowFactory.create(null, {});
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.detail !== ""
            sourceComponent: ({
                    network: networkDetail,
                    bluetooth: bluetoothDetail,
                    audio: audioDetail,
                    mixer: mixerDetail,
                    battery: batteryDetail,
                    tray: trayDetail
                })[root.detail] ?? null
        }
    }

    Component {
        id: networkDetail

        HomeDetails.Network {
            screenState: root.screenState
        }
    }

    Component {
        id: bluetoothDetail

        HomeDetails.Bluetooth {}
    }

    Component {
        id: audioDetail

        HomeDetails.Sound {}
    }

    Component {
        id: mixerDetail

        HomeDetails.Mixer {}
    }

    Component {
        id: batteryDetail

        HomeDetails.Power {}
    }

    Component {
        id: trayDetail

        HomeDetails.TrayMenu {
            item: root.trayItem
            onDone: root.detail = ""
        }
    }

    component Panel: Rectangle {
        radius: 14
        color: Hallownest.card
        border.width: 1
        border.color: Hallownest.border
    }

    component QuickToggle: HkToggle {
        implicitWidth: 30
        implicitHeight: 30
        radius: 15
    }

    component IconButton: MaterialIcon {
        id: iconButton

        property string icon
        property color colour: Hallownest.steel

        signal clicked

        text: icon
        color: iconArea.containsMouse ? Hallownest.soul : colour

        MouseArea {
            id: iconArea

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconButton.clicked()
        }
    }

    component Tile: Rectangle {
        id: tile

        property string icon
        property string title
        property string subtitle
        property bool checked
        property color accent: Hallownest.soul

        signal toggled
        signal more

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 56
        radius: 14
        color: checked ? Qt.alpha(accent, tileArea.containsMouse ? 0.2 : 0.14) : tileArea.containsMouse ? Hallownest.raise(Hallownest.button, 1.6) : Hallownest.button
        border.width: 1
        border.color: checked ? Qt.alpha(accent, 0.55) : Hallownest.border

        Behavior on color {
            CAnim {}
        }

        MouseArea {
            id: tileArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: tile.icon
                color: tile.checked ? tile.accent : Hallownest.subtext
                fill: tile.checked ? 1 : 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: tile.title
                    color: Hallownest.soul
                    font.pointSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: tile.subtitle
                    color: Hallownest.subtext
                    font.pointSize: 8
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: "chevron_right"
                onClicked: tile.more()
            }
        }
    }
}
