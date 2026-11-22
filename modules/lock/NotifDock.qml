pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.hallownest
import qs.services

ColumnLayout {
    id: root

    required property var lock

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    spacing: Tokens.spacing.medium

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: Notifs.list.length > 0 ? Tr.trN("%n notification", "%n notifications", Notifs.list.length) : Tr.tr("Notifications")
            color: Hallownest.steel
            font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
            elide: Text.ElideRight
        }

        HkButton {
            visible: Notifs.list.length > 0 && !Config.lock.hideNotifs
            implicitHeight: 26
            icon: "clear_all"
            text: Tr.tr("Clear")
            onClicked: Notifs.clear()
        }
    }

    ClipRect {
        id: clipRect

        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Tokens.rounding.medium
        color: "transparent"

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: opacity > 0
            opacity: Notifs.list.length > 0 && !Config.lock.hideNotifs ? 0 : 1

            sourceComponent: Arcade {
                id: arcade

                label: Config.lock.hideNotifs ? Tr.tr("Unlock for notifications") : Tr.tr("No notifications")

                Connections {
                    function onGameKey(key: int, pressed: bool, isRepeat: bool): void {
                        if (pressed)
                            arcade.keyPressed(key, isRepeat);
                        else
                            arcade.keyReleased(key);
                    }

                    target: root.lock
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardExtraLarge
                }
            }
        }

        StyledListView {
            anchors.fill: parent
            visible: !Config.lock.hideNotifs
            // An empty list would still steal clicks from the games underneath
            enabled: count > 0
            spacing: Tokens.spacing.small
            clip: true

            model: ScriptModel {
                values: {
                    const list = Notifs.notClosed.map(n => [n.appName, null]);
                    return [...new Map(list).keys()];
                }
            }

            delegate: NotifGroup {}

            add: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    property: "scale"
                    from: 0
                    to: 1
                }
            }

            remove: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    to: 0
                }
                Anim {
                    property: "scale"
                    to: 0.6
                }
            }

            move: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    properties: "opacity,scale"
                    to: 1
                }
                Anim {
                    property: "y"
                }
            }

            displaced: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    properties: "opacity,scale"
                    to: 1
                }
                Anim {
                    property: "y"
                }
            }
        }
    }
}
