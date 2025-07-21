pragma ComponentBehavior: Bound

import qs.services
import qs.config
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: root

    required property Item wrapper
    required property ShellScreen screen
    required property string currentName
    required property real currentCenter
    required property bool hasCurrent

    anchors.centerIn: parent

    implicitWidth: (content.children.find(c => c.shouldBeActive)?.implicitWidth ?? 0) + Appearance.padding.large * 2
    implicitHeight: (content.children.find(c => c.shouldBeActive)?.implicitHeight ?? 0) + Appearance.padding.large * 2

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Appearance.padding.large

        Popout {
            name: "activewindow"
            sourceComponent: ActiveWindow {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "network"
            source: "Network.qml"
        }

        Popout {
            name: "bluetooth"
            source: "Bluetooth.qml"
        }

        Popout {
            name: "battery"
            source: "Battery.qml"
        }

        Repeater {
            model: ScriptModel {
                values: [...SystemTray.items.values]
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData
                required property int index

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    target: root

                    function onHasCurrentChanged(): void {
                        if (root.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root
                        trayItem: trayMenu.modelData.menu
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        property bool shouldBeActive: root.currentName === name

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        opacity: 0
        scale: 0.8
        active: false
        asynchronous: true

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
                popout.scale: 1
            }
        }

        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        properties: "opacity,scale"
                        duration: Appearance.anim.durations.small
                    }
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                    Anim {
                        properties: "opacity,scale"
                    }
                }
            }
        ]
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
