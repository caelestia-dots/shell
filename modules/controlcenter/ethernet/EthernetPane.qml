pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.effects
import qs.components.containers
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        EthernetList {
            anchors.fill: parent
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

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: rightBorder.innerRadius
            color: "transparent"
            clip: true

            Loader {
                id: loader

                property var pane: root.session.ethernet.active
                property string paneId: pane ? (pane.interface || "") : ""

                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 2

                opacity: 1
                scale: 1
                transformOrigin: Item.Center

                clip: true
                asynchronous: true
                sourceComponent: pane ? details : settings

                Behavior on paneId {
                    SequentialAnimation {
                        ParallelAnimation {
                            Anim {
                                target: loader
                                property: "opacity"
                                to: 0
                                easing.bezierCurve: Appearance.anim.curves.standardAccel
                            }
                            Anim {
                                target: loader
                                property: "scale"
                                to: 0.8
                                easing.bezierCurve: Appearance.anim.curves.standardAccel
                            }
                        }
                        PropertyAction {}
                        ParallelAnimation {
                            Anim {
                                target: loader
                                property: "opacity"
                                to: 1
                                easing.bezierCurve: Appearance.anim.curves.standardDecel
                            }
                            Anim {
                                target: loader
                                property: "scale"
                                to: 1
                                easing.bezierCurve: Appearance.anim.curves.standardDecel
                            }
                        }
                    }
                }

                onPaneChanged: {
                    paneId = pane ? (pane.interface || "") : "";
                }
            }
        }

        InnerBorder {
            id: rightBorder

            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: settings

            StyledFlickable {
                flickableDirection: Flickable.VerticalFlick
                contentHeight: settingsInner.height
                clip: true

                EthernetSettings {
                    id: settingsInner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    session: root.session
                }
            }
        }

        Component {
            id: details

            EthernetDetails {
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