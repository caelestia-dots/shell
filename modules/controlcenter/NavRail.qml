pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.modules.controlcenter
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property Session session
    required property bool initialOpeningComplete

    implicitWidth: layout.implicitWidth + Appearance.padding.larger * 4
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Appearance.padding.larger * 2
        spacing: Appearance.spacing.normal

        states: State {
            name: "expanded"
            when: root.session.navExpanded

            PropertyChanges {
                layout.spacing: Appearance.spacing.small
            }
        }

        transitions: Transition {
            Anim {
                properties: "spacing"
            }
        }

        Loader {
            Layout.topMargin: Appearance.spacing.large
            asynchronous: true
            active: !root.session.floating
            visible: active

            sourceComponent: StyledRect {
                readonly property int nonAnimWidth: normalWinIcon.implicitWidth + (root.session.navExpanded ? normalWinLabel.anchors.leftMargin + normalWinLabel.implicitWidth : 0) + normalWinIcon.anchors.leftMargin * 2

                implicitWidth: nonAnimWidth
                implicitHeight: root.session.navExpanded ? normalWinIcon.implicitHeight + Appearance.padding.normal * 2 : nonAnimWidth

                color: Colours.palette.m3primaryContainer
                radius: Appearance.rounding.small

                StateLayer {
                    id: normalWinState

                    color: Colours.palette.m3onPrimaryContainer

                    function onClicked(): void {
                        root.session.root.close();
                        WindowFactory.create(null, {
                            active: root.session.active,
                            navExpanded: root.session.navExpanded
                        });
                    }
                }

                MaterialIcon {
                    id: normalWinIcon

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Appearance.padding.large

                    text: "select_window"
                    color: Colours.palette.m3onPrimaryContainer
                    font.pointSize: Appearance.font.size.large
                    fill: 1
                }

                StyledText {
                    id: normalWinLabel

                    anchors.left: normalWinIcon.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Appearance.spacing.normal

                    text: qsTr("Float window")
                    color: Colours.palette.m3onPrimaryContainer
                    opacity: root.session.navExpanded ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
                }

                Behavior on implicitWidth {
                    Anim {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
            }
        }

        Repeater {
            model: PaneRegistry.count

            NavItem {
                required property int index
                Layout.topMargin: index === 0 ? Appearance.spacing.large * 2 : 0
                icon: PaneRegistry.getByIndex(index).icon
                label: PaneRegistry.getByIndex(index).label
            }
        }
    }

    component NavItem: Item {
        id: item

        required property string icon
        required property string label
        readonly property bool active: root.session.active === label

        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight + smallLabel.implicitHeight + smallLabel.anchors.topMargin

        states: State {
            name: "expanded"
            when: root.session.navExpanded

            PropertyChanges {
                expandedLabel.opacity: 1
                smallLabel.opacity: 0
                background.implicitWidth: icon.implicitWidth + icon.anchors.leftMargin * 2 + expandedLabel.anchors.leftMargin + expandedLabel.implicitWidth
                background.implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2
                item.implicitHeight: background.implicitHeight
            }
        }

        transitions: Transition {
            Anim {
                property: "opacity"
                duration: Appearance.anim.durations.small
            }

            Anim {
                properties: "implicitWidth,implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        StyledRect {
            id: background

            radius: Appearance.rounding.full
            color: Qt.alpha(Colours.palette.m3secondaryContainer, item.active ? 1 : 0)

            implicitWidth: icon.implicitWidth + icon.anchors.leftMargin * 2
            implicitHeight: icon.implicitHeight + Appearance.padding.small

            StateLayer {
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                function onClicked(): void {
                    // Prevent tab switching during initial opening animation to avoid blank pages
                    if (!root.initialOpeningComplete) {
                        return;
                    }
                    root.session.active = item.label;
                }
            }

            MaterialIcon {
                id: icon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Appearance.padding.large

                text: item.icon
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
                fill: item.active ? 1 : 0

                Behavior on fill {
                    Anim {}
                }
            }

            StyledText {
                id: expandedLabel

                anchors.left: icon.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Appearance.spacing.normal

                opacity: 0
                text: item.label
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.capitalization: Font.Capitalize
            }

            StyledText {
                id: smallLabel

                anchors.horizontalCenter: icon.horizontalCenter
                anchors.top: icon.bottom
                anchors.topMargin: Appearance.spacing.small / 2

                text: item.label
                font.pointSize: Appearance.font.size.small
                font.capitalization: Font.Capitalize
            }
        }
    }
}
