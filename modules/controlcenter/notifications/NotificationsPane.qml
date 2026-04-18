pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    required property Session session

    property bool notificationsExpire: GlobalConfig.notifs.expire ?? true
    property string notificationsFullscreen: GlobalConfig.notifs.fullscreen ?? "on"
    property bool notificationsOpenExpanded: Config.notifs.openExpanded ?? false
    property int notificationsDefaultExpireTimeout: GlobalConfig.notifs.defaultExpireTimeout ?? 5000
    property int notificationsGroupPreviewNum: Config.notifs.groupPreviewNum ?? 3

    property int maxToasts: Config.utilities.maxToasts ?? 4
    property string toastsFullscreen: Config.utilities.toasts.fullscreen ?? "off"
    property bool chargingChanged: GlobalConfig.utilities.toasts.chargingChanged ?? true
    property bool gameModeChanged: GlobalConfig.utilities.toasts.gameModeChanged ?? true
    property bool dndChanged: GlobalConfig.utilities.toasts.dndChanged ?? true
    property bool audioOutputChanged: GlobalConfig.utilities.toasts.audioOutputChanged ?? true
    property bool audioInputChanged: GlobalConfig.utilities.toasts.audioInputChanged ?? true
    property bool capsLockChanged: GlobalConfig.utilities.toasts.capsLockChanged ?? true
    property bool numLockChanged: GlobalConfig.utilities.toasts.numLockChanged ?? true
    property bool kbLayoutChanged: GlobalConfig.utilities.toasts.kbLayoutChanged ?? true
    property bool vpnChanged: GlobalConfig.utilities.toasts.vpnChanged ?? true
    property bool nowPlaying: GlobalConfig.utilities.toasts.nowPlaying ?? false

    function saveConfig(): void {
        GlobalConfig.notifs.expire = root.notificationsExpire;
        GlobalConfig.notifs.fullscreen = root.notificationsFullscreen;
        GlobalConfig.notifs.openExpanded = root.notificationsOpenExpanded;
        GlobalConfig.notifs.defaultExpireTimeout = root.notificationsDefaultExpireTimeout;
        GlobalConfig.notifs.groupPreviewNum = root.notificationsGroupPreviewNum;

        GlobalConfig.utilities.maxToasts = root.maxToasts;
        GlobalConfig.utilities.toasts.fullscreen = root.toastsFullscreen;
        GlobalConfig.utilities.toasts.chargingChanged = root.chargingChanged;
        GlobalConfig.utilities.toasts.gameModeChanged = root.gameModeChanged;
        GlobalConfig.utilities.toasts.dndChanged = root.dndChanged;
        GlobalConfig.utilities.toasts.audioOutputChanged = root.audioOutputChanged;
        GlobalConfig.utilities.toasts.audioInputChanged = root.audioInputChanged;
        GlobalConfig.utilities.toasts.capsLockChanged = root.capsLockChanged;
        GlobalConfig.utilities.toasts.numLockChanged = root.numLockChanged;
        GlobalConfig.utilities.toasts.kbLayoutChanged = root.kbLayoutChanged;
        GlobalConfig.utilities.toasts.vpnChanged = root.vpnChanged;
        GlobalConfig.utilities.toasts.nowPlaying = root.nowPlaying;
    }

    anchors.fill: parent

    ClippingRectangle {
        id: notificationsClippingRect

        anchors.fill: parent
        anchors.margins: Tokens.padding.normal
        anchors.leftMargin: 0
        anchors.rightMargin: Tokens.padding.normal

        color: "transparent"
        radius: notificationsBorder.innerRadius

        Loader {
            id: notificationsLoader

            anchors.fill: parent
            anchors.margins: Tokens.padding.large + Tokens.padding.normal
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.large

            sourceComponent: notificationsContentComponent
        }
    }

    InnerBorder {
        id: notificationsBorder

        leftThickness: 0
        rightThickness: Tokens.padding.normal
    }

    Component {
        id: notificationsContentComponent

        StyledFlickable {
            id: notificationsFlickable

            flickableDirection: Flickable.VerticalFlick
            contentHeight: notificationsLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: notificationsFlickable
            }

            RowLayout {
                id: notificationsLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Tokens.spacing.normal

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 500
                    Layout.alignment: Qt.AlignTop
                    spacing: Tokens.spacing.normal

                    SectionContainer {
                        Layout.fillWidth: true
                        alignTop: true

                        StyledText {
                            text: qsTr("Notifications")
                            font.pointSize: Tokens.font.size.normal
                        }

                        SplitButtonRow {
                            id: notificationsFullscreenSelector

                            function syncActiveItem(): void {
                                active = root.notificationsFullscreen === "off" ? notificationsFullscreenOffItem : notificationsFullscreenOnItem;
                            }

                            label: qsTr("Show in fullscreen")
                            menuItems: [notificationsFullscreenOffItem, notificationsFullscreenOnItem]

                            Component.onCompleted: syncActiveItem()

                            Connections {
                                function onNotificationsFullscreenChanged(): void {
                                    notificationsFullscreenSelector.syncActiveItem();
                                }

                                target: root
                            }

                            MenuItem {
                                id: notificationsFullscreenOffItem

                                text: qsTr("Off")
                                icon: "notifications_off"
                                activeText: qsTr("Off")
                                onClicked: {
                                    root.notificationsFullscreen = "off";
                                    root.saveConfig();
                                }
                            }

                            MenuItem {
                                id: notificationsFullscreenOnItem

                                text: qsTr("On")
                                icon: "notifications"
                                activeText: qsTr("On")
                                onClicked: {
                                    root.notificationsFullscreen = "on";
                                    root.saveConfig();
                                }
                            }
                        }

                        SwitchRow {
                            label: qsTr("Expire automatically")
                            checked: root.notificationsExpire
                            onToggled: checked => {
                                root.notificationsExpire = checked;
                                root.saveConfig();
                            }
                        }

                        SwitchRow {
                            label: qsTr("Open expanded")
                            checked: root.notificationsOpenExpanded
                            onToggled: checked => {
                                root.notificationsOpenExpanded = checked;
                                root.saveConfig();
                            }
                        }

                        SpinBoxRow {
                            label: qsTr("Default timeout")
                            value: root.notificationsDefaultExpireTimeout
                            min: 1000
                            max: 60000
                            step: 500
                            onValueModified: value => {
                                root.notificationsDefaultExpireTimeout = value;
                                root.saveConfig();
                            }
                        }

                        SpinBoxRow {
                            label: qsTr("Group preview count")
                            value: root.notificationsGroupPreviewNum
                            min: 1
                            max: 10
                            step: 1
                            onValueModified: value => {
                                root.notificationsGroupPreviewNum = value;
                                root.saveConfig();
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Tokens.spacing.normal

                    SectionContainer {
                        Layout.fillWidth: true
                        alignTop: true

                        StyledText {
                            text: qsTr("Toast settings")
                            font.pointSize: Tokens.font.size.normal
                        }

                        SplitButtonRow {
                            id: toastFullscreenSelector

                            function syncActiveItem(): void {
                                if (root.toastsFullscreen === "all") {
                                    active = toastFullscreenAllItem;
                                    return;
                                }

                                if (root.toastsFullscreen === "important") {
                                    active = toastFullscreenImportantItem;
                                    return;
                                }

                                active = toastFullscreenOffItem;
                            }

                            Layout.fillWidth: true
                            z: expanded ? 100 : 0
                            label: qsTr("Show in fullscreen")
                            menuItems: [toastFullscreenOffItem, toastFullscreenImportantItem, toastFullscreenAllItem]

                            Component.onCompleted: syncActiveItem()

                            Connections {
                                function onToastsFullscreenChanged(): void {
                                    toastFullscreenSelector.syncActiveItem();
                                }

                                target: root
                            }

                            MenuItem {
                                id: toastFullscreenOffItem

                                text: qsTr("Off")
                                icon: "notifications_off"
                                activeText: qsTr("Off")
                                onClicked: {
                                    root.toastsFullscreen = "off";
                                    root.saveConfig();
                                }
                            }

                            MenuItem {
                                id: toastFullscreenImportantItem

                                text: qsTr("Important")
                                icon: "priority_high"
                                activeText: qsTr("Important")
                                onClicked: {
                                    root.toastsFullscreen = "important";
                                    root.saveConfig();
                                }
                            }

                            MenuItem {
                                id: toastFullscreenAllItem

                                text: qsTr("On")
                                icon: "notifications"
                                activeText: qsTr("On")
                                onClicked: {
                                    root.toastsFullscreen = "all";
                                    root.saveConfig();
                                }
                            }
                        }

                        SpinBoxRow {
                            Layout.fillWidth: true
                            label: qsTr("Visible toasts")
                            value: root.maxToasts
                            min: 1
                            max: 10
                            step: 1
                            onValueModified: value => {
                                root.maxToasts = value;
                                root.saveConfig();
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: Tokens.spacing.normal
                            rowSpacing: Tokens.spacing.normal

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Charging changes")
                                checked: root.chargingChanged
                                onToggled: checked => {
                                    root.chargingChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Game mode changes")
                                checked: root.gameModeChanged
                                onToggled: checked => {
                                    root.gameModeChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Do not disturb")
                                checked: root.dndChanged
                                onToggled: checked => {
                                    root.dndChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Audio output changes")
                                checked: root.audioOutputChanged
                                onToggled: checked => {
                                    root.audioOutputChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Audio input changes")
                                checked: root.audioInputChanged
                                onToggled: checked => {
                                    root.audioInputChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Caps lock changes")
                                checked: root.capsLockChanged
                                onToggled: checked => {
                                    root.capsLockChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Num lock changes")
                                checked: root.numLockChanged
                                onToggled: checked => {
                                    root.numLockChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Keyboard layout changes")
                                checked: root.kbLayoutChanged
                                onToggled: checked => {
                                    root.kbLayoutChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("VPN changes")
                                checked: root.vpnChanged
                                onToggled: checked => {
                                    root.vpnChanged = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                label: qsTr("Now playing")
                                checked: root.nowPlaying
                                onToggled: checked => {
                                    root.nowPlaying = checked;
                                    root.saveConfig();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
