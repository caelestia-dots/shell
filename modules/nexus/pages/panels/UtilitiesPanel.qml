pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    function isToggleOn(id: string): bool {
        const item = Config.utilities.quickToggles.values.find(t => t.id === id);
        return item?.enabled ?? false;
    }

    function setToggleOn(id: string, on: bool): void {
        const list = GlobalConfig.utilities.quickToggles;
        for (let i = 0; i < list.count; i++) {
            const item = list.at(i);
            if (item.id === id) {
                item.enabled = on;
                return;
            }
        }
        list.insert({
            id,
            enabled: on
        });
    }

    title: Tr.tr("Utilities")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.trCtx("Enabled", "toggle label")
            subtext: Tr.tr("Show the utilities panel")
            checked: Config.utilities.enabled
            onToggled: GlobalConfig.utilities.enabled = checked
        }

        // Cards
        SectionHeader {
            text: Tr.tr("Cards")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Keep awake")
            subtext: Tr.tr("Show the idle inhibitor card")
            checked: Config.utilities.cards.keepAwake
            onToggled: GlobalConfig.utilities.cards.keepAwake = checked
        }

        ToggleRow {
            text: Tr.tr("Screen recorder")
            subtext: Tr.tr("Show the screen recorder card")
            checked: Config.utilities.cards.recorder
            onToggled: GlobalConfig.utilities.cards.recorder = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Quick toggles")
            subtext: Tr.tr("Show the quick toggles card")
            checked: Config.utilities.cards.quickToggles
            onToggled: GlobalConfig.utilities.cards.quickToggles = checked
        }

        // Quick toggles
        SectionHeader {
            text: Tr.tr("Quick toggles")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Wi-Fi")
            subtext: Tr.tr("Toggle wireless networking")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("wifi")
            onToggled: root.setToggleOn("wifi", checked)
        }

        ToggleRow {
            text: Tr.tr("Bluetooth")
            subtext: Tr.tr("Toggle the Bluetooth adapter")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("bluetooth")
            onToggled: root.setToggleOn("bluetooth", checked)
        }

        ToggleRow {
            text: Tr.tr("Microphone")
            subtext: Tr.tr("Mute or unmute the default source")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("mic")
            onToggled: root.setToggleOn("mic", checked)
        }

        ToggleRow {
            text: Tr.tr("Settings")
            subtext: Tr.tr("Open the settings window")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("settings")
            onToggled: root.setToggleOn("settings", checked)
        }

        ToggleRow {
            text: Tr.tr("Game mode")
            subtext: Tr.tr("Toggle game mode")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("gameMode")
            onToggled: root.setToggleOn("gameMode", checked)
        }

        ToggleRow {
            text: Tr.tr("Do not disturb")
            subtext: Tr.tr("Silence notifications")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("dnd")
            onToggled: root.setToggleOn("dnd", checked)
        }

        ToggleRow {
            last: true
            text: Tr.tr("VPN")
            subtext: Tr.tr("Connect or disconnect the VPN")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("vpn")
            onToggled: root.setToggleOn("vpn", checked)
        }
    }
}
