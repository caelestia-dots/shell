pragma ComponentBehavior: Bound

import ".."
import qs.widgets
import qs.config
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.fillHeight: true

        DeviceList {
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

            session: root.session
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Loader {
            id: loader

            property BluetoothDevice pane: root.session.bt.active

            anchors.fill: parent
            anchors.margins: Appearance.padding.large * 2 + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large * 2
            anchors.rightMargin: Appearance.padding.large * 2 + Appearance.padding.normal / 2

            asynchronous: true
            sourceComponent: pane ? details : settings

            Behavior on pane {
                SequentialAnimation {
                    ParallelAnimation {
                        Anim {
                            property: "opacity"
                            to: 0
                            easing.bezierCurve: Appearance.anim.curves.standardAccel
                        }
                        Anim {
                            property: "scale"
                            to: 0.8
                            easing.bezierCurve: Appearance.anim.curves.standardAccel
                        }
                    }
                    PropertyAction {}
                    ParallelAnimation {
                        Anim {
                            property: "opacity"
                            to: 1
                            easing.bezierCurve: Appearance.anim.curves.standardDecel
                        }
                        Anim {
                            property: "scale"
                            to: 1
                            easing.bezierCurve: Appearance.anim.curves.standardDecel
                        }
                    }
                }
            }
        }

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: settings

            StyledFlickable {
                flickableDirection: Flickable.VerticalFlick
                contentHeight: settingsInner.height

                Settings {
                    id: settingsInner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    session: root.session
                }
            }
        }

        Component {
            id: details

            Details {
                session: root.session
            }
        }
    }

    component Anim: NumberAnimation {
        target: loader
        duration: Appearance.anim.durations.normal / 2
        easing.type: Easing.BezierSpline
    }
}
