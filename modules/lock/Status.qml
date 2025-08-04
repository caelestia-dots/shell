import qs.components
import qs.components.widgets
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

WrapperItem {
    property alias showNotifs: notifs.active

    readonly property real nonAnimWidth: (notifs.item?.count > 0 ? Config.notifs.sizes.width : status.implicitWidth) + margin
    readonly property real nonAnimHeight: {
        if (notifs.active && notifs.item.count > 0) {
            const count = Math.min(notifs.item.count, Config.lock.maxNotifs);
            let height = status.implicitHeight + Appearance.spacing.normal + Appearance.spacing.smaller * (count - 1);
            for (let i = 0; i < count; i++)
                height += notifs.item.itemAtIndex(i)?.nonAnimHeight ?? 0;
            return height + margin;
        }

        return status.implicitHeight + margin;
    }

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    margin: Appearance.padding.large * 2
    rightMargin: 0
    topMargin: 0

    Timer {
        running: true
        interval: 10
        onTriggered: notifs.item?.countChanged()
    }

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    ColumnLayout {
        spacing: Appearance.spacing.normal

        RowLayout {
            id: status

            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                active: UPower.displayDevice.isLaptopBattery
                asynchronous: true

                sourceComponent: StyledText {
                    animate: true
                    text: qsTr("%1%2 remaining").arg(UPower.onBattery ? "" : "(+) ").arg(UPower.displayDevice.percentage)
                    color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? Colours.palette.m3onSurface : Colours.palette.m3error
                }
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter

                animate: true
                text: Network.active ? Icons.getNetworkIcon(Network.active.strength ?? 0) : "wifi_off"
                font.pointSize: Appearance.font.size.large
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.maximumWidth: item?.implicitWidth ?? 0

                active: !UPower.displayDevice.isLaptopBattery
                asynchronous: true

                sourceComponent: StyledText {
                    animate: true
                    text: Network.active?.ssid ?? ""
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter

                animate: true
                text: Bluetooth.defaultAdapter.enabled ? "bluetooth" : "bluetooth_disabled"
                font.pointSize: Appearance.font.size.large
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: !UPower.displayDevice.isLaptopBattery
                asynchronous: true

                sourceComponent: StyledText {
                    animate: true
                    text: qsTr("%n device(s) connected", "", Bluetooth.devices.values.filter(d => d.connected).length)
                    font.pointSize: Appearance.font.size.normal
                }
            }
        }

        Loader {
            id: notifs

            Layout.fillWidth: true
            Layout.fillHeight: true

            sourceComponent: ListView {
                model: ScriptModel {
                    values: [...Notifs.list].reverse()
                }

                orientation: Qt.Vertical
                spacing: 0
                clip: true
                interactive: false

                delegate: Item {
                    id: wrapper

                    required property Notifs.Notif modelData
                    required property int index
                    readonly property alias nonAnimHeight: notif.nonAnimHeight
                    property int idx

                    onIndexChanged: {
                        if (index !== -1)
                            idx = index;
                    }

                    implicitWidth: notif.implicitWidth
                    implicitHeight: notif.nonAnimHeight + (idx === 0 ? 0 : Appearance.spacing.smaller)

                    ListView.onRemove: removeAnim.start()

                    SequentialAnimation {
                        id: removeAnim

                        PropertyAction {
                            target: wrapper
                            property: "ListView.delayRemove"
                            value: true
                        }
                        PropertyAction {
                            target: wrapper
                            property: "enabled"
                            value: false
                        }
                        PropertyAction {
                            target: wrapper
                            property: "implicitHeight"
                            value: 0
                        }
                        PropertyAction {
                            target: wrapper
                            property: "z"
                            value: 1
                        }
                        Anim {
                            target: notif
                            property: "x"
                            to: (notif.x >= 0 ? Config.notifs.sizes.width : -Config.notifs.sizes.width) * 2
                            duration: Appearance.anim.durations.normal
                            easing.bezierCurve: Appearance.anim.curves.emphasized
                        }
                        PropertyAction {
                            target: wrapper
                            property: "ListView.delayRemove"
                            value: false
                        }
                    }

                    ClippingRectangle {
                        anchors.top: parent.top
                        anchors.topMargin: wrapper.idx === 0 ? 0 : Appearance.spacing.smaller

                        color: "transparent"
                        radius: notif.radius
                        implicitWidth: notif.implicitWidth
                        implicitHeight: notif.nonAnimHeight

                        Notification {
                            id: notif

                            modelData: wrapper.modelData
                        }
                    }
                }

                move: Transition {
                    Anim {
                        property: "y"
                        duration: Appearance.anim.durations.large
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                displaced: Transition {
                    Anim {
                        property: "y"
                        duration: Appearance.anim.durations.large
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                ExtraIndicator {
                    anchors.bottom: parent.bottom
                    extra: Notifs.list.length - Config.lock.maxNotifs
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
