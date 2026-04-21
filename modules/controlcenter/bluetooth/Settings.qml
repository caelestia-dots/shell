pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

ColumnLayout {
    id: root

    required property Session session

    spacing: Tokens.spacing.normal

    SettingsHeader {
        icon: "bluetooth"
        title: qsTr("Bluetooth Settings")
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.large
        text: qsTr("Adapter status")
        font.pointSize: Tokens.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("General adapter settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterStatus.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: adapterStatus

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.large

            spacing: Tokens.spacing.larger

            Toggle {
                label: qsTr("Powered")
                checked: Bluetooth.defaultAdapter?.enabled ?? false
                toggle.onToggled: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.enabled = checked;
                }
            }

            Toggle {
                label: qsTr("Discoverable")
                checked: Bluetooth.defaultAdapter?.discoverable ?? false
                toggle.onToggled: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.discoverable = checked;
                }
            }

            Toggle {
                label: qsTr("Pairable")
                checked: Bluetooth.defaultAdapter?.pairable ?? false
                toggle.onToggled: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.pairable = checked;
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.large
        text: qsTr("Adapter properties")
        font.pointSize: Tokens.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Per-adapter settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterSettings.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: adapterSettings

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.large

            spacing: Tokens.spacing.larger

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Current adapter")
                }

                Item {
                    id: adapterPickerButton

                    property bool expanded

                    implicitWidth: adapterPicker.implicitWidth + Tokens.padding.normal * 2
                    implicitHeight: adapterPicker.implicitHeight + Tokens.padding.smaller * 2

                    StateLayer {
                        onClicked: {
                            adapterPickerButton.expanded = !adapterPickerButton.expanded;
                        }

                        radius: Tokens.rounding.small
                    }

                    RowLayout {
                        id: adapterPicker

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.normal
                        anchors.topMargin: Tokens.padding.smaller
                        anchors.bottomMargin: Tokens.padding.smaller
                        spacing: Tokens.spacing.normal

                        StyledText {
                            Layout.leftMargin: Tokens.padding.small
                            text: Bluetooth.defaultAdapter?.name ?? qsTr("None")
                        }

                        MaterialIcon {
                            text: "expand_more"
                        }
                    }

                    Elevation {
                        anchors.fill: adapterListBg
                        radius: adapterListBg.radius
                        opacity: adapterPickerButton.expanded ? 1 : 0
                        scale: adapterPickerButton.expanded ? 1 : 0.7
                        level: 2

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {
                                type: Anim.FastSpatial
                            }
                        }
                    }

                    StyledClippingRect {
                        id: adapterListBg

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        implicitHeight: adapterPickerButton.expanded ? adapterList.implicitHeight : adapterPickerButton.implicitHeight

                        color: Colours.palette.m3secondaryContainer
                        radius: Tokens.rounding.small
                        opacity: adapterPickerButton.expanded ? 1 : 0
                        scale: adapterPickerButton.expanded ? 1 : 0.7

                        ColumnLayout {
                            id: adapterList

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            spacing: 0

                            Repeater {
                                model: Bluetooth.adapters

                                Item {
                                    id: adapter

                                    required property BluetoothAdapter modelData

                                    Layout.fillWidth: true
                                    implicitHeight: adapterInner.implicitHeight + Tokens.padding.normal * 2

                                    StateLayer {
                                        onClicked: {
                                            adapterPickerButton.expanded = false;
                                            root.session.bt.currentAdapter = adapter.modelData;
                                        }

                                        disabled: !adapterPickerButton.expanded
                                    }

                                    RowLayout {
                                        id: adapterInner

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: Tokens.padding.normal
                                        spacing: Tokens.spacing.normal

                                        StyledText {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: Tokens.padding.small
                                            text: adapter.modelData.name
                                            color: Colours.palette.m3onSecondaryContainer
                                        }

                                        MaterialIcon {
                                            text: "check"
                                            color: Colours.palette.m3onSecondaryContainer
                                            visible: adapter.modelData === root.session.bt.currentAdapter
                                        }
                                    }
                                }
                            }
                        }

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {
                                type: Anim.FastSpatial
                            }
                        }

                        Behavior on implicitHeight {
                            Anim {
                                type: Anim.DefaultSpatial
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Discoverable timeout")
                }

                CustomSpinBox {
                    min: 0
                    value: root.session.bt.currentAdapter?.discoverableTimeout ?? 0
                    onValueModified: value => {
                        if (root.session.bt.currentAdapter) {
                            root.session.bt.currentAdapter.discoverableTimeout = value;
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item {
                    id: renameAdapter

                    Layout.fillWidth: true
                    Layout.rightMargin: Tokens.spacing.small

                    implicitHeight: renameLabel.implicitHeight + adapterNameEdit.implicitHeight

                    states: State {
                        name: "editingAdapterName"
                        when: root.session.bt.editingAdapterName

                        AnchorChanges {
                            target: adapterNameEdit
                            anchors.top: renameAdapter.top
                        }
                        PropertyChanges {
                            renameAdapter.implicitHeight: adapterNameEdit.implicitHeight
                            renameLabel.opacity: 0
                            adapterNameEdit.padding: Tokens.padding.normal
                        }
                    }

                    transitions: Transition {
                        AnchorAnim {
                            type: AnchorAnim.Standard
                        }
                        Anim {
                            properties: "implicitHeight,opacity,padding"
                        }
                    }

                    StyledText {
                        id: renameLabel

                        anchors.left: parent.left

                        text: qsTr("Rename adapter (currently does not work)")
                        color: Colours.palette.m3outline
                        font.pointSize: Tokens.font.size.small
                    }

                    StyledTextField {
                        id: adapterNameEdit

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: renameLabel.bottom
                        anchors.leftMargin: root.session.bt.editingAdapterName ? 0 : -Tokens.padding.normal

                        text: root.session.bt.currentAdapter?.name ?? ""
                        readOnly: !root.session.bt.editingAdapterName
                        onAccepted: {
                            root.session.bt.editingAdapterName = false;
                        }

                        leftPadding: Tokens.padding.normal
                        rightPadding: Tokens.padding.normal

                        background: StyledRect {
                            radius: Tokens.rounding.small
                            border.width: 2
                            border.color: Colours.palette.m3primary
                            opacity: root.session.bt.editingAdapterName ? 1 : 0

                            Behavior on border.color {
                                CAnim {}
                            }

                            Behavior on opacity {
                                Anim {}
                            }
                        }

                        Behavior on anchors.leftMargin {
                            Anim {}
                        }
                    }
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: cancelEditIcon.implicitHeight + Tokens.padding.smaller * 2

                    radius: Tokens.rounding.small
                    color: Colours.palette.m3secondaryContainer
                    opacity: root.session.bt.editingAdapterName ? 1 : 0
                    scale: root.session.bt.editingAdapterName ? 1 : 0.5

                    StateLayer {
                        onClicked: {
                            root.session.bt.editingAdapterName = false;
                            adapterNameEdit.text = Qt.binding(() => root.session.bt.currentAdapter?.name ?? "");
                        }

                        color: Colours.palette.m3onSecondaryContainer
                        disabled: !root.session.bt.editingAdapterName
                    }

                    MaterialIcon {
                        id: cancelEditIcon

                        anchors.centerIn: parent
                        animate: true
                        text: "cancel"
                        color: Colours.palette.m3onSecondaryContainer
                    }

                    Behavior on opacity {
                        Anim {}
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: editIcon.implicitHeight + Tokens.padding.smaller * 2

                    radius: root.session.bt.editingAdapterName ? Tokens.rounding.small : implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
                    color: Qt.alpha(Colours.palette.m3primary, root.session.bt.editingAdapterName ? 1 : 0)

                    StateLayer {
                        onClicked: {
                            root.session.bt.editingAdapterName = !root.session.bt.editingAdapterName;
                            if (root.session.bt.editingAdapterName)
                                adapterNameEdit.forceActiveFocus();
                            else
                                adapterNameEdit.accepted();
                        }

                        color: root.session.bt.editingAdapterName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }

                    MaterialIcon {
                        id: editIcon

                        anchors.centerIn: parent
                        animate: true
                        text: root.session.bt.editingAdapterName ? "check_circle" : "edit"
                        color: root.session.bt.editingAdapterName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }

                    Behavior on radius {
                        Anim {}
                    }
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.large
        text: qsTr("Adapter information")
        font.pointSize: Tokens.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Information about the default adapter")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterInfo.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: adapterInfo

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.large

            spacing: Tokens.spacing.small / 2

            StyledText {
                text: qsTr("Adapter state")
            }

            StyledText {
                text: Bluetooth.defaultAdapter ? BluetoothAdapterState.toString(Bluetooth.defaultAdapter.state) : qsTr("Unknown")
                color: Colours.palette.m3outline
                font.pointSize: Tokens.font.size.small
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.normal
                text: qsTr("Dbus path")
            }

            StyledText {
                text: Bluetooth.defaultAdapter?.dbusPath ?? ""
                color: Colours.palette.m3outline
                font.pointSize: Tokens.font.size.small
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.normal
                text: qsTr("Adapter id")
            }

            StyledText {
                text: Bluetooth.defaultAdapter?.adapterId ?? ""
                color: Colours.palette.m3outline
                font.pointSize: Tokens.font.size.small
            }
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle

            cLayer: 2
        }
    }
}
