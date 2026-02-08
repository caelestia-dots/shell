pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services
import "components"
import "pages"

StyledRect {
    id: root

    property int currentPage: 0

    function close(): void {}

    readonly property list<var> pages: [
        { name: "Welcome", icon: "waving_hand" },
        { name: "Getting Started", icon: "rocket_launch" },
    ]

    color: Colours.palette.m3background

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220

            color: Colours.palette.m3surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Logo
                RowLayout {
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 16
                    spacing: 12

                    Text {
                        text: "Caelestia"
                        font.pointSize: 18
                        font.bold: true
                        color: Colours.palette.m3onSurface
                    }
                }

                // Nav
                Repeater {
                    id: navMenu

                    model: root.pages

                    delegate: NavButton {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        text: modelData.name
                        icon: modelData.icon
                        active: root.currentPage === index
                        onClicked: root.currentPage = index
                    }
                }

                Item { Layout.fillHeight: true }

                NavButton {
                    Layout.fillWidth: true
                    text: qsTr("Close")
                    icon: "close"
                    onClicked: QsWindow.window.destroy();
                }
            }

            // Separator
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Colours.palette.m3outlineVariant
            }

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    id: pagesLayout

                    width: parent.width
                    spacing: 0
                    y: -root.currentPage * parent.height

                    Behavior on y {
                        NumberAnimation {
                            duration: Appearance.anim.durations.normal
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Welcome page
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: root.height

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 32
                            contentHeight: welcomeLoader.item ? welcomeLoader.item.implicitHeight : 0
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            Loader {
                                id: welcomeLoader
                                anchors.left: parent.left
                                anchors.right: parent.right
                                sourceComponent: welcomeComponent
                            }
                        }
                    }

                    // Getting Started page
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: root.height

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 32
                            contentHeight: gettingStartedLoader.item ? gettingStartedLoader.item.implicitHeight : 0
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            Loader {
                                id: gettingStartedLoader
                                anchors.left: parent.left
                                anchors.right: parent.right
                                sourceComponent: gettingStartedComponent
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: welcomeComponent
        Welcome {}
    }

    Component {
        id: gettingStartedComponent
        GettingStarted {}
    }
}