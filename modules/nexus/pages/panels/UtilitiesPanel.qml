pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Utilities")
    isSubPage: true

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

        // Quick toggles
        SectionHeader {
            text: qsTr("Quick toggles")
        }

        ToggleRow {
            first: true
            text: qsTr("Wi-Fi")
            subtext: qsTr("Toggle wireless networking")
            checked: root.isToggleOn("wifi")
            onToggled: root.setToggleOn("wifi", checked)
        }

        ToggleRow {
            text: qsTr("Bluetooth")
            subtext: qsTr("Toggle the Bluetooth adapter")
            checked: root.isToggleOn("bluetooth")
            onToggled: root.setToggleOn("bluetooth", checked)
        }

        ToggleRow {
            text: qsTr("Microphone")
            subtext: qsTr("Mute or unmute the default source")
            checked: root.isToggleOn("mic")
            onToggled: root.setToggleOn("mic", checked)
        }

        ToggleRow {
            text: qsTr("Settings")
            subtext: qsTr("Open the settings window")
            checked: root.isToggleOn("settings")
            onToggled: root.setToggleOn("settings", checked)
        }

        ToggleRow {
            text: qsTr("Game mode")
            subtext: qsTr("Toggle game mode")
            checked: root.isToggleOn("gameMode")
            onToggled: root.setToggleOn("gameMode", checked)
        }

        ToggleRow {
            text: qsTr("Do not disturb")
            subtext: qsTr("Silence notifications")
            checked: root.isToggleOn("dnd")
            onToggled: root.setToggleOn("dnd", checked)
        }

        ToggleRow {
            last: true
            text: qsTr("VPN")
            subtext: qsTr("Connect or disconnect the VPN")
            checked: root.isToggleOn("vpn")
            onToggled: root.setToggleOn("vpn", checked)
        }
    }
}
