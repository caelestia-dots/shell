pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var lock

    anchors.fill: parent
    anchors.margins: Appearance.padding.large

    spacing: Appearance.spacing.smaller

    StyledText {
        Layout.fillWidth: true
        text: Notifs.list.length > 0 ? qsTr("%1 notification%2").arg(Notifs.list.length).arg(Notifs.list.length === 1 ? "" : "s") : qsTr("Notifications")
        color: Colours.palette.m3outline
        font.family: Appearance.font.family.mono
        font.weight: 500
        elide: Text.ElideRight
    }

    ClippingRectangle {
        id: clipRect

        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Appearance.rounding.small
        color: "transparent"

        Loader {
            anchors.centerIn: parent
            asynchronous: true
            active: opacity > 0
            opacity: Notifs.list.length > 0 ? 0 : 1

            sourceComponent: ColumnLayout {
                spacing: Appearance.spacing.large

                Image {
                    asynchronous: true
                    source: Qt.resolvedUrl(`${Quickshell.shellDir}/assets/dino.png`)
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: clipRect.width * 0.8

                    layer.enabled: true
                    layer.effect: Colouriser {
                        colorizationColor: Colours.palette.m3outlineVariant
                        brightness: 1
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No Notifications")
                    color: Colours.palette.m3outlineVariant
                    font.pointSize: Appearance.font.size.large
                    font.family: Appearance.font.family.mono
                    font.weight: 500
                }
            }

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.extraLarge
                }
            }
        }

        StyledListView {
            anchors.fill: parent

            spacing: Appearance.spacing.small
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
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
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
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            displaced: Transition {
                Anim {
                    properties: "opacity,scale"
                    to: 1
                }
                Anim {
                    property: "y"
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }
}
