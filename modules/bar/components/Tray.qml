import qs.components
import qs.services
import qs.config
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Shapes

StyledRect {
    id: root

    readonly property alias items: items
    property bool isExpanded: !Config.bar.tray.compact || mouseArea.containsMouse
    

    clip: true
    visible: width > 0 && height > 0

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: {
        if (Config.bar.tray.compact) {
            return layout.implicitHeight + 20 + Appearance.padding.normal * 2 + Appearance.spacing.small + Appearance.padding.small + 30;
        }
        return layout.implicitHeight + (Config.bar.tray.background ? Appearance.padding.normal : Appearance.padding.small) * 2;
    }

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.tray.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Appearance.rounding.full

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: Config.bar.tray.compact
        acceptedButtons: Qt.NoButton
    }

    Rectangle {
        id: compactIndicator
        objectName: "compactIndicator"
        visible: Config.bar.tray.compact
        z: -1

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.padding.small

        width: Config.bar.sizes.innerWidth
        height: 20

        color: Colours.palette.m3surfaceContainer
        opacity: 0.9
        radius: 10

        Shape {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            width: 10
            height: 8
            rotation: mouseArea.containsMouse ? 180 : 0
            transformOrigin: Item.Center

            ShapePath {
                strokeColor: Colours.palette.m3onSurface
                strokeWidth: 1.5
                fillColor: "transparent"

                startX: 2
                startY: 6

                PathLine { x: 5; y: 3 }
                PathLine { x: 8; y: 6 }
            }

            Behavior on rotation {
                Anim {
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }
        }
    }

    Rectangle {
        id: expandedBackground
        visible: Config.bar.tray.compact && root.isExpanded
        z: -1

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: layout.top
        anchors.bottom: layout.bottom
        anchors.topMargin: -Appearance.padding.small
        anchors.bottomMargin: -Appearance.padding.small

        width: Config.bar.sizes.innerWidth

        color: Colours.palette.m3surfaceContainer
        opacity: 0.9
        radius: Appearance.rounding.normal

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }
    }

    Column {
        id: layout
        objectName: "layout"
        z: 1

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: Config.bar.tray.compact ? undefined : parent.verticalCenter
        anchors.bottom: Config.bar.tray.compact ? compactIndicator.top : undefined
        anchors.bottomMargin: Config.bar.tray.compact ? Appearance.spacing.normal : 0
        spacing: Appearance.spacing.normal

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: SystemTray.items

            TrayItem {
                required property int index
                property bool animationComplete: false
                
                opacity: root.isExpanded ? 1 : 0
                enabled: root.isExpanded && animationComplete
                transform: Translate {
                    y: root.isExpanded ? 0 : 30
                    
                    Behavior on y {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: index * 50
                            }
                            Anim {
                                duration: Appearance.anim.durations.normal
                                easing.bezierCurve: Appearance.anim.curves.standardDecel
                            }
                        }
                    }
                }

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: index * 50
                        }
                        Anim {
                            duration: Appearance.anim.durations.normal
                            easing.bezierCurve: Appearance.anim.curves.standardDecel
                        }
                    }
                }
                
                Timer {
                    id: enableTimer
                    interval: index * 50 + Appearance.anim.durations.normal
                    repeat: false
                    running: root.isExpanded
                    onTriggered: animationComplete = true
                }
                
                Connections {
                    target: root
                    function onIsExpandedChanged() {
                        if (!root.isExpanded) {
                            animationComplete = false;
                            enableTimer.stop();
                        }
                    }
                }
            }
        }
    }


    Behavior on implicitWidth {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        enabled: false
    }
}
