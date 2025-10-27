pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: root

    required property Item wrapper
    readonly property Popout currentPopout: content.children.find(c => c.shouldBeActive) ?? null
    readonly property Item current: currentPopout?.item ?? null

    anchors.centerIn: parent

    implicitWidth: (currentPopout?.implicitWidth ?? 0) + Appearance.padding.large * 2
    implicitHeight: (currentPopout?.implicitHeight ?? 0) + Appearance.padding.large * 2

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
            sourceComponent: Network {}
        }

        Popout {
            name: "bluetooth"
            sourceComponent: Bluetooth {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "battery"
            sourceComponent: Battery {}
        }

        Popout {
            name: "audio"
            sourceComponent: Audio {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "kblayout"
            sourceComponent: KbLayout {}
        }

        Popout {
            name: "lockstatus"
            sourceComponent: LockStatus {}
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
                    target: root.wrapper

                    function onHasCurrentChanged(): void {
                        if (root.wrapper.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.wrapper
                        trayItem: trayMenu.modelData.menu
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: root.wrapper.currentName === name

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        opacity: 0
        scale: 0.8
        active: false

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
}
