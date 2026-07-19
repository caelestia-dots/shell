pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    function isToggleOn(id: string): bool {
        const item = Config.utilities.quickToggles.find(t => t.id === id);
        return item ? (item.enabled ?? true) : false;
    }

    function setToggleOn(id: string, on: bool): void {
        let found = false;
        const next = Config.utilities.quickToggles.map(item => {
            if (item.id !== id)
                return item;
            found = true;
            return Object.assign({}, item, {
                enabled: on
            });
        });
        if (!found)
            next.push({
                id,
                enabled: on
            });
        GlobalConfig.utilities.quickToggles = next;
    }

    title: qsTr("Utilities")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Enabled")
            subtext: qsTr("Show the utilities panel")
            checked: Config.utilities.enabled
            onToggled: GlobalConfig.utilities.enabled = checked
        }

        // Cards
        SectionHeader {
            text: qsTr("Cards")
        }

        ToggleRow {
            first: true
            text: qsTr("Keep awake")
            subtext: qsTr("Show the idle inhibitor card")
            checked: Config.utilities.cards.keepAwake
            onToggled: GlobalConfig.utilities.cards.keepAwake = checked
        }

        ToggleRow {
            text: qsTr("Screen recorder")
            subtext: qsTr("Show the screen recorder card")
            checked: Config.utilities.cards.recorder
            onToggled: GlobalConfig.utilities.cards.recorder = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Quick toggles")
            subtext: qsTr("Show the quick toggles card")
            checked: Config.utilities.cards.quickToggles
            onToggled: GlobalConfig.utilities.cards.quickToggles = checked
        }

        // Quick toggles
        SectionHeader {
            text: qsTr("Quick toggles")
        }

        ToggleRow {
            first: true
            text: qsTr("Wi-Fi")
            subtext: qsTr("Toggle wireless networking")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("wifi")
            onToggled: root.setToggleOn("wifi", checked)
        }

        ToggleRow {
            text: qsTr("Bluetooth")
            subtext: qsTr("Toggle the Bluetooth adapter")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("bluetooth")
            onToggled: root.setToggleOn("bluetooth", checked)
        }

        ToggleRow {
            text: qsTr("Microphone")
            subtext: qsTr("Mute or unmute the default source")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("mic")
            onToggled: root.setToggleOn("mic", checked)
        }

        ToggleRow {
            text: qsTr("Settings")
            subtext: qsTr("Open the settings window")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("settings")
            onToggled: root.setToggleOn("settings", checked)
        }

        ToggleRow {
            text: qsTr("Game mode")
            subtext: qsTr("Toggle game mode")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("gameMode")
            onToggled: root.setToggleOn("gameMode", checked)
        }

        ToggleRow {
            text: qsTr("Do not disturb")
            subtext: qsTr("Silence notifications")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("dnd")
            onToggled: root.setToggleOn("dnd", checked)
        }

        ToggleRow {
            last: true
            text: qsTr("VPN")
            subtext: qsTr("Connect or disconnect the VPN")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("vpn")
            onToggled: root.setToggleOn("vpn", checked)
        }
    }
}
