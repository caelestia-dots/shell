pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property BluetoothDevice device: session.bt.active

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: layout.height

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: Icons.getBluetoothIcon(root.device.icon)
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                animate: true
                text: root.device?.name ?? ""
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Connection status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Connection settings for this device")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceStatus.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceStatus

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.larger

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

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Device properties")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Additional settings")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceProps.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceProps

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.larger

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        Item {
                            id: renameDevice

                            Layout.fillWidth: true
                            Layout.rightMargin: Appearance.spacing.small

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
                                    deviceNameEdit.padding: Appearance.padding.normal
                                }
                            }

                            transitions: Transition {
                                AnchorAnimation {
                                    duration: Appearance.anim.durations.normal
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Appearance.anim.curves.standard
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
                                font.pointSize: Appearance.font.size.small
                            }

                            StyledTextField {
                                id: deviceNameEdit

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: renameLabel.bottom
                                anchors.leftMargin: root.session.bt.editingDeviceName ? 0 : -Appearance.padding.normal

                                text: root.device?.name ?? ""
                                readOnly: !root.session.bt.editingDeviceName
                                onAccepted: {
                                    root.session.bt.editingDeviceName = false;
                                    root.device.name = text;
                                }

                                leftPadding: Appearance.padding.normal
                                rightPadding: Appearance.padding.normal

                                background: StyledRect {
                                    radius: Appearance.rounding.small
                                    border.width: 2
                                    border.color: Colours.palette.m3primary
                                    opacity: root.session.bt.editingDeviceName ? 1 : 0

                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: Appearance.anim.durations.normal
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Appearance.anim.curves.standard
                                        }
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
                            implicitHeight: cancelEditIcon.implicitHeight + Appearance.padding.smaller * 2

                            radius: Appearance.rounding.small
                            color: Colours.palette.m3secondaryContainer
                            opacity: root.session.bt.editingDeviceName ? 1 : 0
                            scale: root.session.bt.editingDeviceName ? 1 : 0.5

                            StateLayer {
                                color: Colours.palette.m3onSecondaryContainer
                                disabled: !root.session.bt.editingDeviceName

                                function onClicked(): void {
                                    root.session.bt.editingDeviceName = false;
                                    deviceNameEdit.text = Qt.binding(() => root.device?.name ?? "");
                                }
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
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                            }
                        }

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: editIcon.implicitHeight + Appearance.padding.smaller * 2

                            radius: root.session.bt.editingDeviceName ? Appearance.rounding.small : implicitHeight / 2 * Math.min(1, Appearance.rounding.scale)
                            color: Qt.alpha(Colours.palette.m3primary, root.session.bt.editingDeviceName ? 1 : 0)

                            StateLayer {
                                color: root.session.bt.editingDeviceName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                                function onClicked(): void {
                                    root.session.bt.editingDeviceName = !root.session.bt.editingDeviceName;
                                    if (root.session.bt.editingDeviceName)
                                        deviceNameEdit.forceActiveFocus();
                                    else
                                        deviceNameEdit.accepted();
                                }
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

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Device information")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Information about this device")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceInfo.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceInfo

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    StyledText {
                        text: root.device?.batteryAvailable ? qsTr("Device battery (%1%)").arg(root.device.battery * 100) : qsTr("Battery unavailable")
                    }

                    RowLayout {
                        Layout.topMargin: Appearance.spacing.small / 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: Appearance.padding.smaller
                        spacing: Appearance.spacing.small / 2

                        StyledRect {
                            Layout.fillHeight: true
                            implicitWidth: root.device?.batteryAvailable ? parent.width * root.device.battery : 0
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3primary
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Appearance.rounding.full
                            color: Colours.palette.m3secondaryContainer

                            StyledRect {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: parent.height * 0.25

                                implicitWidth: height
                                radius: Appearance.rounding.full
                                color: Colours.palette.m3primary
                            }
                        }
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Dbus path")
                    }

                    StyledText {
                        text: root.device?.dbusPath ?? ""
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("MAC address")
                    }

                    StyledText {
                        text: root.device?.address ?? ""
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Bonded")
                    }

                    StyledText {
                        text: root.device?.bonded ? qsTr("Yes") : qsTr("No")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("System name")
                    }

                    StyledText {
                        text: root.device?.deviceName ?? ""
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.right: fabRoot.right
        anchors.bottom: fabRoot.top
        anchors.bottomMargin: Appearance.padding.normal

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

                implicitHeight: fabMenuItemInner.implicitHeight + Appearance.padding.larger * 2

                radius: Appearance.rounding.full
                color: Colours.palette.m3primaryContainer

                opacity: 0

                states: State {
                    name: "visible"
                    when: root.session.bt.fabMenuOpen

                    PropertyChanges {
                        fabMenuItem.implicitWidth: fabMenuItemInner.implicitWidth + Appearance.padding.large * 2
                        fabMenuItem.opacity: 1
                        fabMenuItemInner.opacity: 1
                    }
                }

                transitions: [
                    Transition {
                        to: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: (fabMenu.count - 1 - fabMenuItem.index) * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    },
                    Transition {
                        from: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: fabMenuItem.index * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    }
                ]

                StateLayer {
                    function onClicked(): void {
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
                    spacing: Appearance.spacing.normal
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
                                duration: Appearance.anim.durations.small
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: fabRoot

        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitWidth: 64
        implicitHeight: 64

        StyledRect {
            id: fabBg

            anchors.right: parent.right
            anchors.top: parent.top

            implicitWidth: 64
            implicitHeight: 64

            radius: Appearance.rounding.normal
            color: root.session.bt.fabMenuOpen ? Colours.palette.m3primary : Colours.palette.m3primaryContainer

            states: State {
                name: "expanded"
                when: root.session.bt.fabMenuOpen

                PropertyChanges {
                    fabBg.implicitWidth: 48
                    fabBg.implicitHeight: 48
                    fabBg.radius: 48 / 2
                    fab.font.pointSize: Appearance.font.size.larger
                }
            }

            transitions: Transition {
                Anim {
                    properties: "implicitWidth,implicitHeight"
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
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

                color: root.session.bt.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer

                function onClicked(): void {
                    root.session.bt.fabMenuOpen = !root.session.bt.fabMenuOpen;
                }
            }

            MaterialIcon {
                id: fab

                anchors.centerIn: parent
                animate: true
                text: root.session.bt.fabMenuOpen ? "close" : "settings"
                color: root.session.bt.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer
                font.pointSize: Appearance.font.size.large
                fill: 1
            }
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle

            cLayer: 2
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
