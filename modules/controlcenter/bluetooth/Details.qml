pragma ComponentBehavior: Bound

import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

StyledFlickable {
    id: root

    required property Session session
    readonly property BluetoothDevice device: session.bt.active

    flickableDirection: Flickable.VerticalFlick
    contentHeight: detailsWrapper.height

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    Item {
        id: detailsWrapper

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: details.implicitHeight

        DeviceDetails {
            id: details

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            session: root.session
            device: root.device

            headerComponent: Component {
                SettingsHeader {
                    icon: Icons.getBluetoothIcon(root.device?.icon ?? "")
                    title: root.device?.name ?? ""
                }
            }

            sections: [
                Component {
                    ColumnLayout {
                        spacing: Tokens.spacing.normal

                        StyledText {
                            Layout.topMargin: Tokens.spacing.large
                            text: qsTr("Connection status")
                            font.pointSize: Tokens.font.size.larger
                            font.weight: 500
                        }

                        StyledText {
                            text: qsTr("Connection settings for this device")
                            color: Colours.palette.m3outline
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: deviceStatus.implicitHeight + Tokens.padding.large * 2

                            radius: Tokens.rounding.normal
                            color: Colours.tPalette.m3surfaceContainer

                            ColumnLayout {
                                id: deviceStatus

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.large

                                spacing: Tokens.spacing.larger

                                Toggle {
                                    label: qsTr("Connected")
                                    checked: root.device?.connected ?? false
                                    toggle.onToggled: root.device.connected = checked
                                }

                                Toggle {
                                    label: qsTr("Paired")
                                    checked: root.device?.paired ?? false
                                    toggle.onToggled: {
                                        if (root.device.paired)
                                            root.device.forget();
                                        else
                                            root.device.pair();
                                    }
                                }

                                Toggle {
                                    label: qsTr("Blocked")
                                    checked: root.device?.blocked ?? false
                                    toggle.onToggled: root.device.blocked = checked
                                }
                            }
                        }
                    }
                },
                Component {
                    ColumnLayout {
                        spacing: Tokens.spacing.normal

                        StyledText {
                            Layout.topMargin: Tokens.spacing.large
                            text: qsTr("Device properties")
                            font.pointSize: Tokens.font.size.larger
                            font.weight: 500
                        }

                        StyledText {
                            text: qsTr("Additional settings")
                            color: Colours.palette.m3outline
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: deviceProps.implicitHeight + Tokens.padding.large * 2

                            radius: Tokens.rounding.normal
                            color: Colours.tPalette.m3surfaceContainer

                            ColumnLayout {
                                id: deviceProps

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.large

                                spacing: Tokens.spacing.larger

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    Item {
                                        id: renameDevice

                                        Layout.fillWidth: true
                                        Layout.rightMargin: Tokens.spacing.small

                                        implicitHeight: renameLabel.implicitHeight + deviceNameEdit.implicitHeight

                                        states: State {
                                            name: "editingDeviceName"
                                            when: root.session.bt.editingDeviceName

                                            AnchorChanges {
                                                target: deviceNameEdit
                                                anchors.top: renameDevice.top
                                            }
                                            PropertyChanges {
                                                renameDevice.implicitHeight: deviceNameEdit.implicitHeight
                                                renameLabel.opacity: 0
                                                deviceNameEdit.padding: root.Tokens.padding.normal
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

                                            text: qsTr("Device name")
                                            color: Colours.palette.m3outline
                                            font.pointSize: Tokens.font.size.small
                                        }

                                        StyledTextField {
                                            id: deviceNameEdit

                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: renameLabel.bottom
                                            anchors.leftMargin: root.session.bt.editingDeviceName ? 0 : -Tokens.padding.normal

                                            text: root.device?.name ?? ""
                                            readOnly: !root.session.bt.editingDeviceName
                                            onAccepted: {
                                                root.session.bt.editingDeviceName = false;
                                                root.device.name = text;
                                            }

                                            leftPadding: Tokens.padding.normal
                                            rightPadding: Tokens.padding.normal

                                            background: StyledRect {
                                                radius: Tokens.rounding.small
                                                border.width: 2
                                                border.color: Colours.palette.m3primary
                                                opacity: root.session.bt.editingDeviceName ? 1 : 0

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
                                        opacity: root.session.bt.editingDeviceName ? 1 : 0
                                        scale: root.session.bt.editingDeviceName ? 1 : 0.5

                                        StateLayer {
                                            onClicked: {
                                                root.session.bt.editingDeviceName = false;
                                                deviceNameEdit.text = Qt.binding(() => root.device?.name ?? "");
                                            }

                                            color: Colours.palette.m3onSecondaryContainer
                                            disabled: !root.session.bt.editingDeviceName
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

                                        radius: root.session.bt.editingDeviceName ? Tokens.rounding.small : implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
                                        color: Qt.alpha(Colours.palette.m3primary, root.session.bt.editingDeviceName ? 1 : 0)

                                        StateLayer {
                                            onClicked: {
                                                root.session.bt.editingDeviceName = !root.session.bt.editingDeviceName;
                                                if (root.session.bt.editingDeviceName)
                                                    deviceNameEdit.forceActiveFocus();
                                                else
                                                    deviceNameEdit.accepted();
                                            }

                                            color: root.session.bt.editingDeviceName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                        }

                                        MaterialIcon {
                                            id: editIcon

                                            anchors.centerIn: parent
                                            animate: true
                                            text: root.session.bt.editingDeviceName ? "check_circle" : "edit"
                                            color: root.session.bt.editingDeviceName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                        }

                                        Behavior on radius {
                                            Anim {}
                                        }
                                    }
                                }

                                Toggle {
                                    label: qsTr("Trusted")
                                    checked: root.device?.trusted ?? false
                                    toggle.onToggled: root.device.trusted = checked
                                }

                                Toggle {
                                    label: qsTr("Wake allowed")
                                    checked: root.device?.wakeAllowed ?? false
                                    toggle.onToggled: root.device.wakeAllowed = checked
                                }
                            }
                        }
                    }
                },
                Component {
                    ColumnLayout {
                        spacing: Tokens.spacing.normal

                        StyledText {
                            Layout.topMargin: Tokens.spacing.large
                            text: qsTr("Device information")
                            font.pointSize: Tokens.font.size.larger
                            font.weight: 500
                        }

                        StyledText {
                            text: qsTr("Information about this device")
                            color: Colours.palette.m3outline
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: deviceInfo.implicitHeight + Tokens.padding.large * 2

                            radius: Tokens.rounding.normal
                            color: Colours.tPalette.m3surfaceContainer

                            ColumnLayout {
                                id: deviceInfo

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.large

                                spacing: Tokens.spacing.small / 2

                                StyledText {
                                    text: root.device?.batteryAvailable ? qsTr("Device battery (%1%)").arg(root.device.battery * 100) : qsTr("Battery unavailable")
                                }

                                RowLayout {
                                    id: batteryPercent

                                    Layout.topMargin: Tokens.spacing.small / 2
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Tokens.padding.smaller
                                    spacing: Tokens.spacing.small / 2

                                    StyledRect {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Tokens.rounding.full
                                        color: Colours.palette.m3secondaryContainer

                                        StyledRect {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.margins: parent.height * 0.25

                                            implicitWidth: root.device?.batteryAvailable ? batteryPercent.width * root.device.battery : 0
                                            radius: Tokens.rounding.full
                                            color: Colours.palette.m3primary
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.topMargin: Tokens.spacing.normal
                                    text: qsTr("Dbus path")
                                }

                                StyledText {
                                    text: root.device?.dbusPath ?? ""
                                    color: Colours.palette.m3outline
                                    font.pointSize: Tokens.font.size.small
                                }

                                StyledText {
                                    Layout.topMargin: Tokens.spacing.normal
                                    text: qsTr("MAC address")
                                }

                                StyledText {
                                    text: root.device?.address ?? ""
                                    color: Colours.palette.m3outline
                                    font.pointSize: Tokens.font.size.small
                                }

                                StyledText {
                                    Layout.topMargin: Tokens.spacing.normal
                                    text: qsTr("Bonded")
                                }

                                StyledText {
                                    text: root.device?.bonded ? qsTr("Yes") : qsTr("No")
                                    color: Colours.palette.m3outline
                                    font.pointSize: Tokens.font.size.small
                                }

                                StyledText {
                                    Layout.topMargin: Tokens.spacing.normal
                                    text: qsTr("System name")
                                }

                                StyledText {
                                    text: root.device?.deviceName ?? ""
                                    color: Colours.palette.m3outline
                                    font.pointSize: Tokens.font.size.small
                                }
                            }
                        }
                    }
                }
            ]
        }
    }

    ColumnLayout {
        anchors.right: fabRoot.right
        anchors.bottom: fabRoot.top
        anchors.bottomMargin: Tokens.padding.normal

        Repeater {
            id: fabMenu

            model: ListModel {
                ListElement {
                    name: "trust"
                    icon: "handshake"
                }
                ListElement {
                    name: "block"
                    icon: "block"
                }
                ListElement {
                    name: "pair"
                    icon: "missing_controller"
                }
                ListElement {
                    name: "connect"
                    icon: "bluetooth_connected"
                }
            }

            StyledClippingRect {
                id: fabMenuItem

                required property var modelData
                required property int index

                Layout.alignment: Qt.AlignRight

                implicitHeight: fabMenuItemInner.implicitHeight + Tokens.padding.larger * 2

                radius: Tokens.rounding.full
                color: Colours.palette.m3primaryContainer

                opacity: 0

                states: State {
                    name: "visible"
                    when: root.session.bt.fabMenuOpen

                    PropertyChanges {
                        fabMenuItem.implicitWidth: fabMenuItemInner.implicitWidth + root.Tokens.padding.large * 2
                        fabMenuItem.opacity: 1
                        fabMenuItemInner.opacity: 1
                    }
                }

                transitions: [
                    Transition {
                        to: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: (fabMenu.count - 1 - fabMenuItem.index) * Tokens.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    type: Anim.FastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    type: Anim.StandardSmall
                                }
                            }
                        }
                    },
                    Transition {
                        from: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: fabMenuItem.index * Tokens.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    type: Anim.FastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    type: Anim.StandardSmall
                                }
                            }
                        }
                    }
                ]

                StateLayer {
                    onClicked: {
                        root.session.bt.fabMenuOpen = false;

                        const name = fabMenuItem.modelData.name;
                        if (fabMenuItem.modelData.name !== "pair")
                            root.device[`${name}ed`] = !root.device[`${name}ed`];
                        else if (root.device.paired)
                            root.device.forget();
                        else
                            root.device.pair();
                    }
                }

                RowLayout {
                    id: fabMenuItemInner

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.normal
                    opacity: 0

                    MaterialIcon {
                        text: fabMenuItem.modelData.icon
                        color: Colours.palette.m3onPrimaryContainer
                        fill: 1
                    }

                    StyledText {
                        animate: true
                        text: (root.device && root.device[`${fabMenuItem.modelData.name}ed`] ? fabMenuItem.modelData.name === "connect" ? "dis" : "un" : "") + fabMenuItem.modelData.name
                        color: Colours.palette.m3onPrimaryContainer
                        font.capitalization: Font.Capitalize
                        Layout.preferredWidth: implicitWidth

                        Behavior on Layout.preferredWidth {
                            Anim {
                                type: Anim.StandardSmall
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: fabRoot

        x: root.contentX + root.width - width
        y: root.contentY + root.height - height
        width: 64
        height: 64
        z: 10000

        StyledRect {
            id: fabBg

            anchors.right: parent.right
            anchors.top: parent.top

            implicitWidth: 64
            implicitHeight: 64

            radius: Tokens.rounding.normal
            color: root.session.bt.fabMenuOpen ? Colours.palette.m3primary : Colours.palette.m3primaryContainer

            states: State {
                name: "expanded"
                when: root.session.bt.fabMenuOpen

                PropertyChanges {
                    fabBg.implicitWidth: 48
                    fabBg.implicitHeight: 48
                    fabBg.radius: 48 / 2
                    fab.font.pointSize: Tokens.font.size.larger
                }
            }

            transitions: Transition {
                Anim {
                    properties: "implicitWidth,implicitHeight"
                    type: Anim.FastSpatial
                }
                Anim {
                    properties: "radius,font.pointSize"
                }
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: fabState.containsMouse && !fabState.pressed ? 4 : 3
            }

            StateLayer {
                id: fabState

                onClicked: {
                    root.session.bt.fabMenuOpen = !root.session.bt.fabMenuOpen;
                }

                color: root.session.bt.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer
            }

            MaterialIcon {
                id: fab

                anchors.centerIn: parent
                animate: true
                text: root.session.bt.fabMenuOpen ? "close" : "settings"
                color: root.session.bt.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer
                font.pointSize: Tokens.font.size.large
                fill: 1
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
