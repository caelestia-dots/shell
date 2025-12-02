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
            id: networkPopout
            name: "network"
            sourceComponent: Network {
                wrapper: root.wrapper
                view: "wireless"
            }
        }

        Popout {
            name: "ethernet"
            sourceComponent: Network {
                wrapper: root.wrapper
                view: "ethernet"
            }
        }

        Popout {
            id: passwordPopout
            name: "wirelesspassword"
            sourceComponent: WirelessPassword {
                id: passwordComponent
                wrapper: root.wrapper
                network: networkPopout.item?.passwordNetwork ?? null
            }
            
            Connections {
                target: root.wrapper
                function onCurrentNameChanged() {
                    // Update network immediately when password popout becomes active
                    if (root.wrapper.currentName === "wirelesspassword") {
                        // Set network immediately if available
                        if (networkPopout.item && networkPopout.item.passwordNetwork) {
                            if (passwordPopout.item) {
                                passwordPopout.item.network = networkPopout.item.passwordNetwork;
                            }
                        }
                        // Also try after a short delay in case networkPopout.item wasn't ready
                        Qt.callLater(() => {
                            if (passwordPopout.item && networkPopout.item && networkPopout.item.passwordNetwork) {
                                passwordPopout.item.network = networkPopout.item.passwordNetwork;
                            }
                        }, 100);
                    }
                }
            }
            
            Connections {
                target: networkPopout
                function onItemChanged() {
                    // When network popout loads, update password popout if it's active
                    if (root.wrapper.currentName === "wirelesspassword" && passwordPopout.item) {
                        Qt.callLater(() => {
                            if (networkPopout.item && networkPopout.item.passwordNetwork) {
                                passwordPopout.item.network = networkPopout.item.passwordNetwork;
                            }
                        });
                    }
                }
            }
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
