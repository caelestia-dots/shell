pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property bool hydrationSettingsOpen: false
    property bool steamSettingsOpen: false

    title: Tr.tr("Complements")

    component SettingRow: RowLayout {
        property alias label: settingLabel.text
        property alias subtext: settingSub.text
        property alias value: spin.value
        property alias from: spin.from
        property alias to: spin.to
        property alias stepSize: spin.stepSize
        signal moved(value: real)

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: settingLabel
                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                id: settingSub
                Layout.fillWidth: true
                visible: text.length > 0
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledSpinBox {
            id: spin
            cLayer: 2
            onValueModified: parent.moved(value)
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Available")
        }

        ToggleRow {
            first: true
            leadingIcon: "verified_user"
            text: Tr.tr("Madison VPN")
            subtext: MadisonVpn.enabled
                ? (MadisonVpn.connected ? MadisonVpn.statusText : Tr.tr("FortiClient / openfortivpn status icon and connect flow"))
                : Tr.tr("Disabled — tunnel and related processes are stopped")
            checked: GlobalConfig.addons.madisonVpn.enabled
            onToggled: MadisonVpn.setEnabled(checked)
        }

        ToggleRow {
            leadingIcon: "timer"
            text: Tr.tr("Timers")
            subtext: Timers.enabled
                ? Tr.tr("Quick timers from the clock popout")
                : Tr.tr("Disabled — active timers are cleared")
            checked: GlobalConfig.addons.timers.enabled
            onToggled: Timers.setEnabled(checked)
        }

        ConnectedRect {
            id: hydrationCard

            Layout.fillWidth: true
            implicitHeight: hydrationCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: hydrationCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "water_drop"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Hydration")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Hydration.enabled
                                ? (root.hydrationSettingsOpen
                                    ? Tr.tr("%1 ml · reminder every %2 min").arg(GlobalConfig.addons.hydration.dailyGoalMl).arg(GlobalConfig.addons.hydration.reminderMinutes)
                                    : Tr.tr("Replaces the dashboard calendar with a water intake tracker"))
                                : Tr.tr("Disabled — calendar stays on the dashboard")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    IconButton {
                        visible: Hydration.enabled
                        isRound: true
                        icon: root.hydrationSettingsOpen ? "expand_less" : "expand_more"
                        type: IconButton.Text
                        font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                        padding: Tokens.padding.small
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.hydrationSettingsOpen = !root.hydrationSettingsOpen
                    }

                    StyledSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: GlobalConfig.addons.hydration.enabled
                        onToggled: {
                            Hydration.setEnabled(checked);
                            if (!checked)
                                root.hydrationSettingsOpen = false;
                            else
                                root.hydrationSettingsOpen = true;
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: Hydration.enabled && root.hydrationSettingsOpen
                    spacing: Tokens.spacing.small

                    SettingRow {
                        label: Tr.tr("Daily goal")
                        subtext: Tr.tr("Target water intake per day (ml)")
                        value: GlobalConfig.addons.hydration.dailyGoalMl
                        from: 500
                        to: 8000
                        stepSize: 100
                        onMoved: v => Hydration.setDailyGoal(v)
                    }

                    SettingRow {
                        label: Tr.tr("Reminder interval")
                        subtext: Tr.tr("Minutes without a sip before a reminder")
                        value: GlobalConfig.addons.hydration.reminderMinutes
                        from: 5
                        to: 120
                        stepSize: 5
                        onMoved: v => Hydration.setReminderMinutes(v)
                    }

                    SettingRow {
                        label: Tr.tr("Preset 1")
                        subtext: Tr.tr("Quick-add button amount (ml)")
                        value: GlobalConfig.addons.hydration.presetMl0
                        from: 1
                        to: 1000
                        stepSize: 1
                        onMoved: v => Hydration.setPreset(0, v)
                    }

                    SettingRow {
                        label: Tr.tr("Preset 2")
                        value: GlobalConfig.addons.hydration.presetMl1
                        from: 1
                        to: 1000
                        stepSize: 1
                        onMoved: v => Hydration.setPreset(1, v)
                    }

                    SettingRow {
                        label: Tr.tr("Preset 3")
                        value: GlobalConfig.addons.hydration.presetMl2
                        from: 1
                        to: 1000
                        stepSize: 1
                        onMoved: v => Hydration.setPreset(2, v)
                    }

                    SettingRow {
                        label: Tr.tr("Preset 4")
                        value: GlobalConfig.addons.hydration.presetMl3
                        from: 1
                        to: 1000
                        stepSize: 1
                        onMoved: v => Hydration.setPreset(3, v)
                    }
                }
            }
        }

        ConnectedRect {
            id: steamCard

            Layout.fillWidth: true
            last: true
            implicitHeight: steamCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: steamCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "sports_esports"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Games (Steam)")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Steam.statusText
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    IconButton {
                        visible: Steam.enabled
                        isRound: true
                        icon: root.steamSettingsOpen ? "expand_less" : "expand_more"
                        type: IconButton.Text
                        font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                        padding: Tokens.padding.small
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.steamSettingsOpen = !root.steamSettingsOpen
                    }

                    StyledSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: GlobalConfig.addons.steam.enabled
                        onToggled: {
                            Steam.setEnabled(checked);
                            if (!checked)
                                root.steamSettingsOpen = false;
                            else
                                root.steamSettingsOpen = true;
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: Steam.enabled && root.steamSettingsOpen
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("Steam API key")
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("From steamcommunity.com/dev/apikey")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        StyledTextField {
                            Layout.preferredWidth: Tokens.sizes.nexus.textFieldWidth
                            Layout.maximumWidth: steamCol.width / 2
                            Layout.alignment: Qt.AlignVCenter
                            verticalPadding: Tokens.padding.small
                            echoMode: TextInput.Password
                            text: GlobalConfig.addons.steam.apiKey
                            placeholderText: Tr.tr("API key")
                            onEditingFinished: Steam.setApiKey(text)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("Steam ID")
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("SteamID64, vanity name, or profile URL")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        StyledTextField {
                            Layout.preferredWidth: Tokens.sizes.nexus.textFieldWidth
                            Layout.maximumWidth: steamCol.width / 2
                            Layout.alignment: Qt.AlignVCenter
                            verticalPadding: Tokens.padding.small
                            text: GlobalConfig.addons.steam.steamId
                            placeholderText: Tr.tr("Steam ID or vanity")
                            onEditingFinished: Steam.setSteamId(text)
                        }
                    }

                    SettingRow {
                        label: Tr.tr("Auto refresh")
                        subtext: Tr.tr("Minutes between automatic Steam updates")
                        value: GlobalConfig.addons.steam.refreshMinutes
                        from: 1
                        to: 180
                        stepSize: 1
                        onMoved: v => Steam.setRefreshMinutes(v)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Item {
                            Layout.fillWidth: true
                        }

                        IconButton {
                            isRound: true
                            icon: "refresh"
                            type: IconButton.Text
                            font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                            padding: Tokens.padding.small
                            enabled: Steam.configured
                            onClicked: Steam.reload()
                        }

                        StyledText {
                            text: Tr.tr("Refresh now")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            text: Tr.tr("Madison VPN config: ~/.config/openfortivpn/config (popout gear). Scripts: ~/.local/share/madison-vpn/")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
