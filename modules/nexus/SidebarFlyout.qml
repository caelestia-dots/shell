pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property NexusSession session

    property string flyoutCategory: ""
    property bool open: false
    readonly property var currentCat: flyoutCategory !== "" ? NexusRegistry.getById(flyoutCategory) : null
    readonly property int childCount: currentCat?.children?.length ?? 0
    readonly property real drawerWidth: drawer.width
    readonly property real drawerHeight: drawer.height

    property string _prevCategory: ""
    property var _prevCat: null

    signal hoverEntered
    signal hoverExited
    signal childClicked(string id)

    implicitWidth: drawer.targetWidth + 2
    implicitHeight: drawer.targetHeight

    onFlyoutCategoryChanged: {
        if (flyoutCategory === "") {
            _prevCategory = "";
            contentFadeOut.start();
        } else if (_prevCategory === "") {
            _prevCategory = flyoutCategory;
            _prevCat = NexusRegistry.getById(flyoutCategory);
            contentFadeOut.stop();
            contentContainer.opacity = 0;
            contentFadeIn.restart();
        } else {
            contentFadeOut.start();
        }
    }

    Rectangle {
        id: drawer

        property real targetWidth: 100
        property real targetHeight: (root.currentCat?.children?.length ?? 0) * 68 + 46 || 80

        width: root.open ? targetWidth : 0
        height: root.open ? targetHeight : drawer.height
        clip: true
        color: "transparent"
        radius: 0

        Behavior on width {
            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Behavior on height {
            Anim {
                type: Anim.DefaultSpatial
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.hoverEntered();
                else
                    root.hoverExited();
            }
        }

        Item {
            id: contentContainer

            anchors.fill: parent
            anchors.margins: 12
            opacity: 1

            NumberAnimation {
                id: contentFadeOut

                target: contentContainer
                property: "opacity"
                from: 1
                to: 0
                duration: 120
                onFinished: {
                    root._prevCategory = root.flyoutCategory;
                    root._prevCat = root.currentCat;
                    contentFadeIn.start();
                }
            }

            NumberAnimation {
                id: contentFadeIn

                target: contentContainer
                property: "opacity"
                from: 0
                to: 1
                duration: 250
            }

            // Category label
            StyledText {
                id: flyoutLabel

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                text: root._prevCat?.label ?? ""
                color: Qt.alpha(Colours.palette.m3onSurface, 0.35)
                font.pointSize: Tokens.font.size.small - 1
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                id: childColumn

                anchors.top: flyoutLabel.bottom
                anchors.topMargin: 6
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 6

                Repeater {
                    model: root._prevCat?.children ?? []

                    delegate: Item {
                        id: flyoutChild

                        required property var modelData

                        readonly property bool isActive: root.session.activeCategory === flyoutChild.modelData.id

                        width: childColumn.width
                        height: 64

                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rounding.normal
                            color: flyoutChild.isActive ? Qt.alpha(Colours.palette.m3primary, 0.16) : "transparent"

                            Behavior on color {
                                CAnim {}
                            }

                            StateLayer {
                                radius: Tokens.rounding.normal
                                color: flyoutChild.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                onClicked: root.childClicked(flyoutChild.modelData.id)
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 3

                                MaterialIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: flyoutChild.modelData.icon
                                    color: flyoutChild.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                    font.pointSize: Tokens.font.size.larger
                                    fill: flyoutChild.isActive ? 1 : 0

                                    Behavior on fill {
                                        Anim {}
                                    }
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: flyoutChild.modelData.label.length > 12 ? flyoutChild.modelData.label.substring(0, 11) + "…" : flyoutChild.modelData.label
                                    color: flyoutChild.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                    font.pointSize: Tokens.font.size.small - 1
                                    font.capitalization: Font.Capitalize
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
