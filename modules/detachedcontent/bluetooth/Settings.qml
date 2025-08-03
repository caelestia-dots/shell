pragma ComponentBehavior: Bound

import ".."
import qs.widgets
import qs.services
import qs.config
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: "bluetooth"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Bluetooth settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Adapter status")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("General adapter settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterStatus.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainer

        ColumnLayout {
            id: adapterStatus

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.larger

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
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Adapter properties")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Per-adapter settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterSettings.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainer

        ColumnLayout {
            id: adapterSettings

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.larger

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Current adapter")
                }

                Item {
                    id: adapterPickerButton

                    property bool expanded

                    implicitWidth: adapterPicker.implicitWidth + Appearance.padding.normal * 2
                    implicitHeight: adapterPicker.implicitHeight + Appearance.padding.smaller * 2

                    StateLayer {
                        radius: Appearance.rounding.small

                        function onClicked(): void {
                            adapterPickerButton.expanded = !adapterPickerButton.expanded;
                        }
                    }

                    RowLayout {
                        id: adapterPicker

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        anchors.topMargin: Appearance.padding.smaller
                        anchors.bottomMargin: Appearance.padding.smaller
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.leftMargin: Appearance.padding.small
                            text: Bluetooth.defaultAdapter?.name ?? qsTr("None")
                        }

                        MaterialIcon {
                            text: "expand_more"
                        }
                    }

                    RectangularShadow {
                        anchors.fill: adapterListBg
                        radius: adapterListBg.radius
                        color: Qt.alpha(Colours.palette.m3shadow, 0.7)
                        opacity: adapterPickerButton.expanded ? 1 : 0
                        scale: adapterPickerButton.expanded ? 1 : 0.7
                        blur: 5
                        spread: 0

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

                    StyledClippingRect {
                        id: adapterListBg

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        implicitHeight: adapterPickerButton.expanded ? adapterList.implicitHeight : adapterPickerButton.implicitHeight

                        color: Colours.palette.m3secondaryContainer
                        radius: Appearance.rounding.small
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
                                    implicitHeight: adapterInner.implicitHeight + Appearance.padding.normal * 2

                                    StateLayer {
                                        disabled: !adapterPickerButton.expanded

                                        function onClicked(): void {
                                            adapterPickerButton.expanded = false;
                                            root.session.bt.currentAdapter = adapter.modelData;
                                        }
                                    }

                                    RowLayout {
                                        id: adapterInner

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: Appearance.padding.normal
                                        spacing: Appearance.spacing.normal

                                        StyledText {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: Appearance.padding.small
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
                                duration: Appearance.anim.durations.expressiveFastSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                            }
                        }

                        Behavior on implicitHeight {
                            Anim {
                                duration: Appearance.anim.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Discoverable timeout")
                }

                CustomSpinBox {
                    min: 0
                    value: root.session.bt.currentAdapter.discoverableTimeout
                    onValueModified: value => root.session.bt.currentAdapter.discoverableTimeout = value
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                Item {
                    id: renameAdapter

                    Layout.fillWidth: true
                    Layout.rightMargin: Appearance.spacing.small

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
                            adapterNameEdit.padding: Appearance.padding.normal
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

                        text: qsTr("Rename adapter (currently does not work)")  // FIXME: remove disclaimer when fixed
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledTextField {
                        id: adapterNameEdit

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: renameLabel.bottom
                        anchors.leftMargin: root.session.bt.editingAdapterName ? 0 : -Appearance.padding.normal

                        text: root.session.bt.currentAdapter.name
                        readOnly: !root.session.bt.editingAdapterName
                        onAccepted: {
                            root.session.bt.editingAdapterName = false;
                            // Doesn't work for now, will be added to QS later
                            // root.session.bt.currentAdapter.name = text;
                        }

                        leftPadding: Appearance.padding.normal
                        rightPadding: Appearance.padding.normal

                        background: StyledRect {
                            radius: Appearance.rounding.small
                            border.width: 2
                            border.color: Colours.palette.m3primary
                            opacity: root.session.bt.editingAdapterName ? 1 : 0

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
                    opacity: root.session.bt.editingAdapterName ? 1 : 0
                    scale: root.session.bt.editingAdapterName ? 1 : 0.5

                    StateLayer {
                        color: Colours.palette.m3onSecondaryContainer
                        disabled: !root.session.bt.editingAdapterName

                        function onClicked(): void {
                            root.session.bt.editingAdapterName = false;
                            adapterNameEdit.text = Qt.binding(() => root.session.bt.currentAdapter.name);
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

                    radius: root.session.bt.editingAdapterName ? Appearance.rounding.small : implicitHeight / 2
                    color: root.session.bt.editingAdapterName ? Colours.palette.m3primary : "transparent"

                    StateLayer {
                        color: root.session.bt.editingAdapterName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                        function onClicked(): void {
                            root.session.bt.editingAdapterName = !root.session.bt.editingAdapterName;
                            if (root.session.bt.editingAdapterName)
                                adapterNameEdit.forceActiveFocus();
                            else
                                adapterNameEdit.accepted();
                        }
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

    Item {
        Layout.fillHeight: true
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
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
