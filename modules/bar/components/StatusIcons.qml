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
    readonly property alias items: iconColumn

    readonly property int spacing: Tokens.spacing.medium / 2

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
            id: repeater

            model: ScriptModel {
                values: root.Config.bar.statusIcons.filter(e => e.enabled ?? true)
            }

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "lockStatus"
                    delegate: EntryWrapper {
                        margin: Hypr.capsLock || Hypr.numLock ? root.spacing / 2 : 0

                        Behavior on margin {
                            Anim {
                                type: Anim.SlowEffects
                            }
                        }

                        LockStatus {
                            id: lockStatus

                            colour: root.colour
                            parentSpacing: root.spacing
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audio"
                    delegate: EntryWrapper {
                        MaterialIcon {
                            animate: true
                            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                            color: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "microphone"
                    delegate: EntryWrapper {
                        MaterialIcon {
                            animate: true
                            text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                            color: root.colour
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
        default property Item item
        readonly property string name: modelData.id.toLowerCase()

        Layout.topMargin: index === 0 ? 0 : margin
        Layout.bottomMargin: index === repeater.count - 1 ? 0 : margin
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
