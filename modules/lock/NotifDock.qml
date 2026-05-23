pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property var lock

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    spacing: Tokens.spacing.smaller

    StyledText {
        Layout.fillWidth: true
        text: Notifs.list.length > 0 ? qsTr("%1 notification%2").arg(Notifs.list.length).arg(Notifs.list.length === 1 ? "" : "s") : qsTr("Notifications")
        color: Colours.palette.m3outline
        font.family: Tokens.font.family.mono
        font.weight: 500
        elide: Text.ElideRight
    }

    ClippingRectangle {
        id: clipRect

        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Tokens.rounding.small
        color: "transparent"

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: opacity > 0
            opacity: Notifs.list.length > 0 && !Config.lock.hideNotifs ? 0 : 1

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.large

                Image {
                    asynchronous: true
                    source: Paths.absolutePath(Config.paths.lockNoNotifsPic)
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: clipRect.width * 0.8 * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

                    layer.enabled: true
                    layer.effect: Colouriser {
                        colorizationColor: Colours.palette.m3outlineVariant
                        brightness: 1
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Config.lock.hideNotifs ? qsTr("Unlock for Notifications") : qsTr("No Notifications")
                    color: Colours.palette.m3outlineVariant
                    font.pointSize: Tokens.font.size.large
                    font.family: Tokens.font.family.mono
                    font.weight: 500
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
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    property: "scale"
                    from: 0
                    to: 1
                    type: Anim.DefaultSpatial
                }
            }

            remove: Transition {
                Anim {
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
                    properties: "opacity,scale"
                    to: 1
                }
                Anim {
                    property: "y"
                    type: Anim.DefaultSpatial
                }
            }

            displaced: Transition {
                Anim {
                    properties: "opacity,scale"
                    to: 1
                }
                Anim {
                    property: "y"
                    type: Anim.DefaultSpatial
                }
            }
        }
    }
}
