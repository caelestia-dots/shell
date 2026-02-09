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
        { name: qsTr("Welcome"), icon: "waving_hand", component: welcomeComponent },
        { name: qsTr("Features"), icon: "star" },
        { name: qsTr("Getting Started"), icon: "rocket_launch", component: gettingStartedComponent },
        { name: qsTr("Community"), icon: "people" },
        { name: qsTr("Get Involved"), icon: "code" },
    ]

    color: Colours.palette.m3background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: logo.height + Appearance.padding.small * 2
            Layout.alignment: Qt.AlignTop

            color: Colours.palette.m3surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.padding.small
                spacing: Appearance.spacing.small

                // Logo
                RowLayout {
                    id: logo

                    Layout.leftMargin: Appearance.padding.small
                    Layout.rightMargin: Appearance.padding.small

                    Text {
                        text: "Caelestia"
                        font.pointSize: Appearance.font.size.large
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

                NavButton {
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Appearance.padding.small
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

                // Content loader
                Item {
                    Layout.fillWidth: true
                    implicitHeight: root.height

                    Flickable {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.padding.large
                        anchors.rightMargin: Appearance.padding.large
                        anchors.bottomMargin: Appearance.padding.large
                        contentHeight: contentLoader.item ? contentLoader.item.implicitHeight + Appearance.padding.large * 2 : 0
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Loader {
                            id: contentLoader
                            anchors.fill: parent
                            sourceComponent: root.pages[root.currentPage].component
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