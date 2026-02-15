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

Item {
    id: root

    required property Notifs.Notif notif

    Layout.fillWidth: true
    implicitHeight: flickable.contentHeight

    layer.enabled: true
    layer.smooth: true
    layer.effect: OpacityMask {
        maskSource: gradientMask
    }

    Item {
        id: gradientMask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.1
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.9
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left

            implicitWidth: parent.width / 2
            opacity: flickable.contentX > 0 ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right

            implicitWidth: parent.width / 2
            opacity: flickable.contentX < flickable.contentWidth - parent.width ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }
    }

    StyledFlickable {
        id: flickable

        anchors.fill: parent
        contentWidth: Math.max(width, actionList.implicitWidth)
        contentHeight: actionList.implicitHeight

        RowLayout {
            id: actionList

            anchors.fill: parent
            spacing: Appearance.spacing.small

            Repeater {
                model: [
                    {
                        isClose: true
                    },
                    ...root.notif.actions,
                    {
                        isCopy: true
                    }
                ]

                StyledRect {
                    id: action

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: actionInner.implicitWidth + Appearance.padding.normal * 2
                    implicitHeight: actionInner.implicitHeight + Appearance.padding.small * 2

                    Layout.preferredWidth: implicitWidth + (actionStateLayer.pressed ? Appearance.padding.large : 0)
                    radius: actionStateLayer.pressed ? Appearance.rounding.small / 2 : Appearance.rounding.small
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 4)

                    Timer {
                        id: copyTimer

                        interval: 3000
                        onTriggered: actionInner.item.text = "content_copy"
                    }

                    StateLayer {
                        id: actionStateLayer

                        function onClicked(): void {
                            if (action.modelData.isClose) {
                                root.notif.close();
                            } else if (action.modelData.isCopy) {
                                Quickshell.clipboardText = root.notif.body;
                                actionInner.item.text = "inventory";
                                copyTimer.start();
                            } else if (action.modelData.invoke) {
                                action.modelData.invoke();
                            } else if (!root.notif.resident) {
                                root.notif.close();
                            }
                        }
                    }

                    Loader {
                        id: actionInner

                        anchors.centerIn: parent
                        sourceComponent: action.modelData.isClose || action.modelData.isCopy ? iconBtn : root.notif.hasActionIcons ? iconComp : textComp
                    }

                    Component {
                        id: iconBtn

                        MaterialIcon {
                            animate: action.modelData.isCopy ?? false
                            text: action.modelData.isCopy ? "content_copy" : "close"
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    Component {
                        id: iconComp

                        IconImage {
                            source: Quickshell.iconPath(action.modelData.identifier)
                        }
                    }

                    Component {
                        id: textComp

                        StyledText {
                            text: action.modelData.text
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }

                    Behavior on radius {
                        Anim {
                            duration: Appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                        }
                    }
                }
            }
        }
    }
}
