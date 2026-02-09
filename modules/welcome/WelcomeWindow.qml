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
        { name: qsTr("Welcome"), icon: "waving_hand" },
        { name: qsTr("Features"), icon: "star" },
        { name: qsTr("Getting Started"), icon: "rocket_launch" },
        { name: qsTr("Community"), icon: "people" },
        { name: qsTr("Get Involved"), icon: "code" },
    ]

    color: Colours.palette.m3background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.alignment: Qt.AlignTop

            color: Colours.palette.m3surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // Logo
                RowLayout {
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8

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

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    delegate: NavButton {
                        required property int index
                        required property var modelData

                        text: modelData.name
                        icon: modelData.icon
                        active: root.currentPage === index
                        onClicked: root.currentPage = index
                    }
                }

                // Item { Layout.fillWidth: true }

                NavButton {
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: 8
                    icon: "close"
                    onClicked: QsWindow.window.destroy();
                }
            }
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

    Component {
        id: welcomeComponent
        Welcome {}
    }

    Component {
        id: gettingStartedComponent
        GettingStarted {}
    }
}