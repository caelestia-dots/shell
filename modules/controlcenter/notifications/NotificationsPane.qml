pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    property bool notificationsExpire: Config.notifs.expire ?? true
    property string notificationsFullscreen: Config.notifs.fullscreen ?? "on"
    property bool notificationsOpenExpanded: Config.notifs.openExpanded ?? false
    property int notificationsDefaultExpireTimeout: Config.notifs.defaultExpireTimeout ?? 5000
    property int notificationsGroupPreviewNum: Config.notifs.groupPreviewNum ?? 3

    property int maxToasts: Config.utilities.maxToasts ?? 4
    property string toastsFullscreen: Config.utilities.toasts.fullscreen ?? "off"
    property bool chargingChanged: Config.utilities.toasts.chargingChanged ?? true
    property bool gameModeChanged: Config.utilities.toasts.gameModeChanged ?? true
    property bool dndChanged: Config.utilities.toasts.dndChanged ?? true
    property bool audioOutputChanged: Config.utilities.toasts.audioOutputChanged ?? true
    property bool audioInputChanged: Config.utilities.toasts.audioInputChanged ?? true
    property bool capsLockChanged: Config.utilities.toasts.capsLockChanged ?? true
    property bool numLockChanged: Config.utilities.toasts.numLockChanged ?? true
    property bool kbLayoutChanged: Config.utilities.toasts.kbLayoutChanged ?? true
    property bool vpnChanged: Config.utilities.toasts.vpnChanged ?? true
    property bool nowPlaying: Config.utilities.toasts.nowPlaying ?? false

    anchors.fill: parent

    function saveConfig(): void {
        Config.notifs.expire = root.notificationsExpire;
        Config.notifs.fullscreen = root.notificationsFullscreen;
        Config.notifs.openExpanded = root.notificationsOpenExpanded;
        Config.notifs.defaultExpireTimeout = root.notificationsDefaultExpireTimeout;
        Config.notifs.groupPreviewNum = root.notificationsGroupPreviewNum;

        Config.utilities.maxToasts = root.maxToasts;
        Config.utilities.toasts.fullscreen = root.toastsFullscreen;
        Config.utilities.toasts.chargingChanged = root.chargingChanged;
        Config.utilities.toasts.gameModeChanged = root.gameModeChanged;
        Config.utilities.toasts.dndChanged = root.dndChanged;
        Config.utilities.toasts.audioOutputChanged = root.audioOutputChanged;
        Config.utilities.toasts.audioInputChanged = root.audioInputChanged;
        Config.utilities.toasts.capsLockChanged = root.capsLockChanged;
        Config.utilities.toasts.numLockChanged = root.numLockChanged;
        Config.utilities.toasts.kbLayoutChanged = root.kbLayoutChanged;
        Config.utilities.toasts.vpnChanged = root.vpnChanged;
        Config.utilities.toasts.nowPlaying = root.nowPlaying;

        Config.save();
    }

    ClippingRectangle {
        id: notificationsClippingRect

        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        anchors.leftMargin: 0
        anchors.rightMargin: Appearance.padding.normal

        color: "transparent"
        radius: notificationsBorder.innerRadius

        Loader {
            id: notificationsLoader

            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large

            sourceComponent: notificationsContentComponent
        }
    }

    InnerBorder {
        id: notificationsBorder

        leftThickness: 0
        rightThickness: Appearance.padding.normal
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

            ColumnLayout {
                id: notificationsLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Appearance.spacing.normal

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Notifications")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }
                }

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true

                    StyledText {
                        text: qsTr("Popup notifications")
                        font.pointSize: Appearance.font.size.normal
                    }

                    SwitchRow {
                        label: qsTr("Expire automatically")
                        checked: root.notificationsExpire
                        onToggled: checked => {
                            root.notificationsExpire = checked;
                            root.saveConfig();
                        }
                    }

                    SplitButtonRow {
                        id: notificationsFullscreenSelector

                        label: qsTr("Show in fullscreen")
                        menuItems: [
                            notificationsFullscreenOffItem,
                            notificationsFullscreenOnItem
                        ]

                        function syncActiveItem(): void {
                            active = root.notificationsFullscreen === "off" ? notificationsFullscreenOffItem : notificationsFullscreenOnItem;
                        }

                        Component.onCompleted: syncActiveItem()

                        Connections {
                            target: root

                            function onNotificationsFullscreenChanged(): void {
                                notificationsFullscreenSelector.syncActiveItem();
                            }
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

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true

                    StyledText {
                        text: qsTr("Toasts")
                        font.pointSize: Appearance.font.size.normal
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal
                        z: toastFullscreenSelector.expanded ? 100 : 0

                        SplitButtonRow {
                            id: toastFullscreenSelector

                            Layout.fillWidth: true
                            label: qsTr("Show in fullscreen")
                            menuItems: [
                                toastFullscreenOffItem,
                                toastFullscreenImportantItem,
                                toastFullscreenAllItem
                            ]

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

                            Component.onCompleted: syncActiveItem()

                            Connections {
                                target: root

                                function onToastsFullscreenChanged(): void {
                                    toastFullscreenSelector.syncActiveItem();
                                }
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
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: Appearance.spacing.normal
                        rowSpacing: Appearance.spacing.normal

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
