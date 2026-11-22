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

    implicitWidth: 640
    implicitHeight: detail ? detailView.implicitHeight : overview.implicitHeight

    ColumnLayout {
        id: overview

        anchors.left: parent.left
        anchors.right: parent.right
        visible: !root.detail
        spacing: Tokens.spacing.small + 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small + 2

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
                checked: root.charging || root.battery <= 0.2
                accent: root.battery <= 0.2 && !root.charging ? Hallownest.grimm : root.charging ? Hallownest.unn : Hallownest.soul
                onToggled: root.detail = "battery"
                onMore: root.detail = "battery"
            }
        }

        Panel {
            Layout.fillWidth: true
            implicitHeight: 42

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.small + 2
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
                    colour: Audio.muted ? Hallownest.steel : Hallownest.lifeblood
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
                    colour: Hallownest.subtext
                    onClicked: root.detail = "mixer"
                }

                IconButton {
                    icon: "chevron_right"
                    colour: Hallownest.subtext
                    onClicked: root.detail = "audio"
                }
            }
        }

        Panel {
            Layout.fillWidth: true
            visible: !!root.player
            implicitHeight: 52

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open("media")
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small + 2
                spacing: Tokens.spacing.medium

                ClippingRectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 8
                    color: Hallownest.void_
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
                        sourceSize.width: 72
                        sourceSize.height: 72
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle || Tr.tr("Unknown title")
                        color: Hallownest.soul
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: (root.player?.trackArtist ?? "") !== ""
                        text: root.player?.trackArtist ?? ""
                        color: Hallownest.subtext
                        font.pointSize: 8.5
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.extraSmall

                    IconButton {
                        visible: root.player?.canGoPrevious ?? false
                        icon: "skip_previous"
                        colour: Hallownest.subtext
                        onClicked: root.player?.previous()
                    }

                    HkButton {
                        icon: root.player?.isPlaying ? "pause" : "play_arrow"
                        filled: true
                        disabled: !(root.player?.canTogglePlaying ?? false)
                        onClicked: root.player?.togglePlaying()
                    }

                    IconButton {
                        visible: root.player?.canGoNext ?? false
                        icon: "skip_next"
                        colour: Hallownest.subtext
                        onClicked: root.player?.next()
                    }
                }
            }
        }

        HkDivider {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            opacity: 0.65
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: NotchPages.tools

                GhostAction {
                    required property var modelData

                    icon: modelData.icon
                    text: modelData.label
                    onClicked: root.open(modelData.id)
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Repeater {
                model: ScriptModel {
                    values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
                }

                Rectangle {
                    id: traySlot

                    required property SystemTrayItem modelData

                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: trayArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.5) : "transparent"

                    Behavior on color {
                        CAnim {}
                    }

                    ColouredIcon {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: Icons.getTrayIcon(traySlot.modelData.id, traySlot.modelData.icon)
                        colour: trayArea.containsMouse ? Hallownest.soul : Hallownest.steel
                        layer.enabled: Config.bar.tray.recolour
                    }

                    MouseArea {
                        id: trayArea

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: event => {
                            if (event?.button === Qt.MiddleButton) {
                                traySlot.modelData.secondaryActivate();
                            } else if (traySlot.modelData.hasMenu && (event?.button === Qt.RightButton || traySlot.modelData.onlyMenu)) {
                                root.trayItem = traySlot.modelData;
                                root.detail = "tray";
                            } else {
                                traySlot.modelData.activate();
                            }
                        }
                    }
                }
            }

            Rectangle {
                implicitWidth: capsuleRow.implicitWidth + 6
                implicitHeight: 30
                radius: 15
                color: Hallownest.card
                border.width: 1
                border.color: Hallownest.border

                RowLayout {
                    id: capsuleRow

                    anchors.centerIn: parent
                    spacing: 2

                    CapsuleToggle {
                        icon: Audio.sourceMuted ? "mic_off" : "mic"
                        checked: Audio.sourceMuted
                        accent: Hallownest.grimm
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }

                    CapsuleToggle {
                        icon: "coffee"
                        checked: RuntimeState.inhibitIdle
                        accent: Hallownest.gold
                        onClicked: RuntimeState.inhibitIdle = !RuntimeState.inhibitIdle
                    }

                    CapsuleToggle {
                        icon: "notifications_off"
                        checked: PersistentState.doNotDisturb
                        accent: Hallownest.grimm
                        onClicked: PersistentState.doNotDisturb = !PersistentState.doNotDisturb
                    }

                    Rectangle {
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2
                        implicitWidth: 1
                        implicitHeight: 14
                        color: Hallownest.border
                    }

                    CapsuleToggle {
                        visible: !Recorder.running
                        icon: "videocam"
                        onClicked: Recorder.start()
                    }

                    CapsuleToggle {
                        visible: !Recorder.running
                        icon: "crop_free"
                        onClicked: {
                            // slurp needs the notch out of the way to pick the region
                            root.screenState.notch = false;
                            Recorder.start(["-r"]);
                        }
                    }

                    CapsuleToggle {
                        visible: Recorder.running
                        icon: "stop_circle"
                        text: Recorder.elapsedText()
                        checked: true
                        accent: Hallownest.grimm
                        onClicked: Recorder.stop()
                    }
                }
            }

            GhostAction {
                icon: "settings"
                onClicked: {
                    root.screenState.notch = false;
                    WindowFactory.create(null, {});
                }
            }

            GhostAction {
                icon: "power_settings_new"
                accent: Hallownest.grimm
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
        id: panel

        radius: 13
        color: Hallownest.card
        border.width: 1
        border.color: Hallownest.border

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: panel.radius
            anchors.rightMargin: panel.radius
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 0.5
                    color: Qt.alpha(Hallownest.soul, Hallownest.light ? 0.14 : 0.08)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }
    }

    component GhostAction: Rectangle {
        id: ghost

        property string icon
        property string text
        property color accent: Hallownest.soul

        signal clicked

        implicitWidth: text ? ghostRow.implicitWidth + 16 : 28
        implicitHeight: 28
        radius: text ? 9 : 14
        color: ghostArea.containsMouse ? (accent === Hallownest.soul ? Hallownest.raise(Hallownest.card, 1.55) : Qt.alpha(accent, 0.14)) : "transparent"
        scale: ghostArea.pressed ? 0.94 : 1

        Behavior on color {
            CAnim {}
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Row {
            id: ghostRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: ghost.icon !== ""
                text: ghost.icon
                color: ghostArea.containsMouse ? ghost.accent : (ghost.accent === Hallownest.soul ? Hallownest.steel : Qt.alpha(ghost.accent, 0.72))
                fontStyle: Tokens.font.icon.small
                animate: true
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: ghost.text !== ""
                text: ghost.text
                color: ghostArea.containsMouse ? Hallownest.soul : Hallownest.subtext
                font.pointSize: 8.5
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: ghostArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ghost.clicked()
        }
    }

    component CapsuleToggle: Rectangle {
        id: cap

        property string icon
        property string text
        property bool checked
        property color accent: Hallownest.soul

        signal clicked

        implicitWidth: text ? capRow.implicitWidth + 14 : 26
        implicitHeight: 24
        radius: 12
        color: checked ? Qt.alpha(accent, capArea.containsMouse ? 0.24 : 0.16) : capArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.65) : "transparent"
        scale: capArea.pressed ? 0.93 : 1

        Behavior on color {
            CAnim {}
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Row {
            id: capRow

            anchors.centerIn: parent
            spacing: 4

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: cap.icon
                color: cap.checked ? cap.accent : capArea.containsMouse ? Hallownest.soul : Hallownest.steel
                fill: cap.checked ? 1 : 0
                fontStyle: Tokens.font.icon.small
                animate: true
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: cap.text !== ""
                text: cap.text
                color: cap.accent
                font.family: Hallownest.mono
                font.pointSize: 8.5
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: capArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cap.clicked()
        }
    }

    component IconButton: MaterialIcon {
        id: iconButton

        property string icon
        property color colour: Hallownest.steel
        readonly property alias hovered: iconArea.containsMouse

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
        implicitHeight: 54
        radius: 13
        color: checked ? Qt.tint(Hallownest.card, Qt.alpha(accent, tileArea.containsMouse ? 0.12 : 0.07)) : tileArea.containsMouse ? Hallownest.raise(Hallownest.card, 1.35) : Hallownest.card
        border.width: 1
        border.color: checked ? Qt.alpha(accent, tileArea.containsMouse ? 0.45 : 0.3) : Hallownest.border

        Behavior on color {
            CAnim {}
        }

        Behavior on border.color {
            CAnim {}
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: tile.radius
            anchors.rightMargin: tile.radius
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 0.5
                    color: Qt.alpha(tile.checked ? tile.accent : Hallownest.soul, Hallownest.light ? 0.18 : 0.11)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
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
            spacing: Tokens.spacing.small + 2

            MaterialIcon {
                text: tile.icon
                color: tile.checked ? tile.accent : Hallownest.subtext
                fill: tile.checked ? 1 : 0
                animate: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    id: titleRow

                    Layout.fillWidth: true
                    spacing: 5

                    StyledText {
                        Layout.maximumWidth: Math.max(1, titleRow.width - 12)
                        text: tile.title
                        color: Hallownest.soul
                        font.pointSize: 9.5
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        implicitWidth: 4
                        implicitHeight: 4
                        rotation: 45
                        color: tile.accent
                        opacity: tile.checked ? 0.85 : 0

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
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
                id: tileMore

                icon: "chevron_right"
                colour: Hallownest.subtext
                opacity: tileArea.containsMouse || tileMore.hovered ? 0.9 : 0.32
                onClicked: tile.more()

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }
}
