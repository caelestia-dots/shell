pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.components.status

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconRow

    readonly property bool isHorizontal: Config.bar.alignment === "top" || Config.bar.alignment === "bottom"
    readonly property int spacing: Tokens.spacing.medium / 2

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
        return false;
    }

    function getHoveredPopout(lx: real, ly: real): string {
        const itemX = lx - iconRow.x;
        const itemY = ly - iconRow.y;
        
        if (itemX < 0 || itemY < 0 || itemX > iconRow.width || itemY > iconRow.height) 
            return "";

        let child = iconRow.childAt(itemX, itemY);
        
        while (child && child !== iconRow) {
            if (child.name !== undefined) return child.name;
            child = child.parent;
        }
        return "";
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: isHorizontal ? (iconRow.implicitWidth + Tokens.padding.medium * 2) : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : (iconRow.implicitHeight + Tokens.padding.medium * 2)

    GridLayout {
        id: iconRow

        anchors.centerIn: parent

        flow: root.isHorizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        rowSpacing: 0
        columnSpacing: 0

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
                            colour: root.colour
                            parentSpacing: root.spacing
                            isHorizontal: root.isHorizontal
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
                            color: root.colour
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
                            color: root.colour
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
                            color: root.colour
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
                            color: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: EntryWrapper {
                        BluetoothStatus {
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "battery"
                    delegate: EntryWrapper {
                        BatteryStatus {
                            colour: root.colour
                        }
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        property int margin: root.spacing / 2
        readonly property bool present: !root.collapsed(modelData)
        property real leadGap: present && index !== root.firstPresent ? margin : 0
        property real trailGap: present && index !== root.lastPresent ? margin : 0
        default property Item item
        property string name: modelData.id.toLowerCase()

        Layout.leftMargin: root.isHorizontal ? Math.round(leadGap) : 0
        Layout.rightMargin: root.isHorizontal ? Math.round(trailGap) : 0
        Layout.topMargin: !root.isHorizontal ? Math.round(leadGap) : 0
        Layout.bottomMargin: !root.isHorizontal ? Math.round(trailGap) : 0
        Layout.alignment: root.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item

        Behavior on leadGap {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on trailGap {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
