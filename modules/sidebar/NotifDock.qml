pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Props props

    anchors.fill: parent
    anchors.margins: Appearance.padding.normal

    Component.onCompleted: Notifs.list.forEach(n => n.popup = false)

    StyledText {
        id: title

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.small

        text: Notifs.list.length > 0 ? qsTr("%1 notification%2").arg(Notifs.list.length).arg(Notifs.list.length === 1 ? "" : "s") : qsTr("Notifications")
        color: Colours.palette.m3outline
        font.pointSize: Appearance.font.size.normal
        font.family: Appearance.font.family.mono
        font.weight: 500
        elide: Text.ElideRight
    }

    ClippingRectangle {
        id: clipRect

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Appearance.spacing.smaller

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

            model: ScriptModel {
                values: [...new Set(Notifs.list.filter(n => !n.closed).map(n => n.appName))].reverse()
            }

            delegate: MouseArea {
                id: notif

                required property int index
                required property string modelData

                property int startY

                function closeAll(): void {
                    for (const n of Notifs.list.filter(n => !n.closed && n.appName === modelData))
                        n.close();
                }

                implicitWidth: root.width
                implicitHeight: notifInner.implicitHeight

                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : undefined
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                preventStealing: true

                drag.target: this
                drag.axis: Drag.XAxis

                onPressed: event => {
                    if (event.button === Qt.LeftButton)
                        startY = event.y;
                    else if (event.button === Qt.RightButton)
                        notifInner.toggleExpand();
                    else if (event.button === Qt.MiddleButton)
                        closeAll();
                }
                onPositionChanged: event => {
                    if (pressed) {
                        const diffY = event.y - startY;
                        if (Math.abs(diffY) > Config.notifs.expandThreshold)
                            notifInner.toggleExpand(diffY > 0);
                    }
                }
                onReleased: event => {
                    if (Math.abs(x) < width * Config.notifs.clearThreshold)
                        x = 0;
                    else
                        closeAll();
                }

                NotifGroup {
                    id: notifInner

                    modelData: notif.modelData
                    props: root.props
                }

                Behavior on x {
                    Anim {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
            }

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

    Timer {
        id: clearTimer

        repeat: true
        interval: 50
        onTriggered: {
            if (Notifs.list.length > 0)
                Notifs.list[0].close();
            else
                stop();
        }
    }

    Loader {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.padding.normal

        scale: Notifs.list.length > 0 ? 1 : 0.5
        opacity: Notifs.list.length > 0 ? 1 : 0
        active: opacity > 0

        sourceComponent: IconButton {
            id: clearBtn

            icon: "clear_all"
            radius: Appearance.rounding.normal
            padding: Appearance.padding.normal
            font.pointSize: Math.round(Appearance.font.size.large * 1.3)
            onClicked: clearTimer.start()

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: clearBtn.stateLayer.containsMouse ? 4 : 3
            }
        }

        Behavior on scale {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
            }
        }
    }
}
