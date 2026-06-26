pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter // qmllint disable unresolved-type

    function setScan(on: bool): void {
        if (adapter?.enabled)
            adapter.discovering = on;
    }

    title: qsTr("Pair new device")
    isSubPage: true

    Component.onCompleted: setScan(true)
    Component.onDestruction: setScan(false)
    onVisibleChanged: setScan(visible)

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Connections {
            function onEnabledChanged(): void {
                if (root.adapter && !root.adapter.enabled)
                    root.nState.closeSubPage();
            }

            target: root.adapter
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: headerText.implicitHeight + Tokens.padding.medium * 2
            first: true

            StyledText {
                id: headerText

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.large
                anchors.verticalCenterOffset: Math.round(fontInfo.pointSize * 0.2)

                text: qsTr("Available devices")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }
        }

        ItemList {
            id: deviceList

            Layout.fillWidth: true
            showList: true
            extraHeight: scanIndicator.implicitHeight
            last: true
            placeholderIcon: "bluetooth_searching"
            placeholderText: qsTr("Searching for devices…")
            list.anchors.top: scanIndicator.bottom

            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => !d.bonded).sort((a, b) => (b.pairing - a.pairing) || a.name.localeCompare(b.name)) // qmllint disable unresolved-type
            }

            delegate: Item {
                id: newDevice

                required property BluetoothDevice modelData
                required property int index
                property real textOpacity: modelData?.pairing ? 0.5 : 1
                property bool wasPairing

                anchors.left: deviceList.list.contentItem.left
                anchors.right: deviceList.list.contentItem.right
                implicitHeight: newLayout.implicitHeight + newLayout.anchors.margins * 2

                Behavior on textOpacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Connections {
                    function onPairedChanged(): void {
                        if (newDevice.wasPairing && newDevice.modelData?.paired)
                            root.nState.closeSubPage();
                    }

                    target: newDevice.modelData
                }

                StateLayer {
                    radius: Tokens.rounding.extraSmall
                    bottomLeftRadius: newDevice.index === deviceList?.list.count - 1 ? Tokens.rounding.extraLarge : radius
                    bottomRightRadius: newDevice.index === deviceList?.list.count - 1 ? Tokens.rounding.extraLarge : radius
                    disabled: newDevice.modelData?.pairing ?? false

                    onClicked: {
                        newDevice.modelData?.pair();
                        newDevice.wasPairing = true;
                    }
                }

                RowLayout {
                    id: newLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: Icons.getBluetoothIcon(newDevice.modelData?.icon ?? "")
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        opacity: newDevice.textOpacity
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        opacity: newDevice.textOpacity

                        StyledText {
                            Layout.fillWidth: true
                            text: newDevice.modelData?.name || qsTr("Unknown device")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: newDevice.modelData?.pairing ? qsTr("Pairing...") : (newDevice.modelData?.address ?? "")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            animate: true
                        }
                    }

                    Loader {
                        asynchronous: true
                        active: opacity > 0
                        opacity: newDevice.modelData?.pairing ? 1 : 0

                        sourceComponent: LoadingIndicator {
                            implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }
                }
            }

            StyledProgressBar {
                id: scanIndicator

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                implicitHeight: Tokens.rounding.extraSmall
                indeterminate: true

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }
}
