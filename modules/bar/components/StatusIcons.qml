pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.components.status

// MadisonVpn used by vpn entry click handling

StyledRect {
    id: root

    required property var popouts
    required property Item bar

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    readonly property int spacing: Tokens.spacing.medium / 2
    readonly property int iconPad: Tokens.padding.extraSmall

    // Index of the first/last entry that isn't collapsed, for edge margin gating
    readonly property int firstPresent: {
        const values = model.values;
        for (let i = 0; i < values.length; i++)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }
    readonly property int lastPresent: {
        const values = model.values;
        for (let i = values.length - 1; i >= 0; i--)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }

    // Entries that can shrink to nothing, spacing included
    function collapsed(entry: var): bool {
        if (entry.id === "lockStatus")
            return !Hypr.capsLock && !Hypr.numLock;
        // Desktops have no battery / power-profile UI in the status strip
        if (entry.id === "battery")
            return !UPower.displayDevice.isLaptopBattery;
        // Hide updates badge when there is nothing to install (keep visible while installing)
        if (entry.id === "updates")
            return !Updates.hasUpdates && !Updates.busy && !Updates.installing;
        // Complements: Madison VPN can be turned off entirely
        if (entry.id === "vpn")
            return !MadisonVpn.enabled;
        return false;
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: iconColumn.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: iconColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.medium

        spacing: 0

        Repeater {
            model: ScriptModel {
                id: model

                values: root.Config.bar.statusIcons.values.filter(e => e.enabled)
            }

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "lockStatus"
                    delegate: EntryWrapper {
                        LockStatus {
                            colour: parent.iconColour
                            parentSpacing: root.spacing
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audio"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            animate: true
                            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                            color: parent.iconColour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "microphone"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2
                        name: "audio" // Mic opens audio popout

                        MaterialIcon {
                            animate: true
                            text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                            color: parent.iconColour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: EntryWrapper {
                        StyledText {
                            animate: true
                            text: Hypr.kbLayout
                            color: parent.iconColour
                            font: Tokens.font.mono.medium
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "network"
                    delegate: EntryWrapper {
                        MaterialIcon {
                            animate: true
                            text: Nmcli.activeEthernet ? "cable" : Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                            color: parent.iconColour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: EntryWrapper {
                        BluetoothStatus {
                            colour: parent.iconColour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: EntryWrapper {
                        VpnStatus {
                            colour: parent.iconColour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "updates"
                    delegate: EntryWrapper {
                        UpdatesStatus {
                            colour: parent.iconColour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "battery"
                    delegate: EntryWrapper {
                        BatteryStatus {
                            colour: parent.iconColour
                        }
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        id: wrap

        required property var modelData
        required property int index
        property int margin: root.spacing / 2
        readonly property bool present: !root.collapsed(modelData)
        property real topGap: present && index !== root.firstPresent ? margin : 0
        property real bottomGap: present && index !== root.lastPresent ? margin : 0
        default property Item item
        property string name: modelData.id.toLowerCase()

        readonly property bool menuOpen: root.popouts?.hasCurrent && root.popouts?.currentName === name
        readonly property bool highlighted: hover.containsMouse || menuOpen
        readonly property color iconColour: highlighted ? Colours.palette.m3onPrimary : root.colour

        Layout.topMargin: Math.round(topGap)
        Layout.bottomMargin: Math.round(bottomGap)
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: present ? implicitHeight : 0
        visible: present
        clip: true
        opacity: present ? 1 : 0

        implicitWidth: present ? (item?.implicitWidth ?? 0) + root.iconPad * 2 : 0
        implicitHeight: present ? (item?.implicitHeight ?? 0) + root.iconPad * 2 : 0

        onItemChanged: {
            if (!item)
                return;
            item.parent = wrap;
            item.anchors.centerIn = wrap;
        }

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: wrap.highlighted ? Colours.palette.m3primary : "transparent"
            z: -1

            Behavior on color {
                CAnim {}
            }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Behavior on topGap {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on bottomGap {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
