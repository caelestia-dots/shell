pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.controls
import qs.config
import qs.services
import "components"
import "pages"

StyledRect {
    id: root

    property string currentPage: "welcome"

    function close(): void {
    }

    readonly property list<var> pages: [
        {
            id: "welcome",
            name: qsTr("Welcome"),
            icon: "waving_hand",
            component: welcomeComponent
        },
        {
            id: "features",
            name: qsTr("Features"),
            icon: "star",
            component: null
        },
        {
            id: "getting-started",
            name: qsTr("Getting Started"),
            icon: "rocket_launch",
            component: gettingStartedComponent
        },
        {
            id: "community",
            name: qsTr("Community"),
            icon: "people",
            component: null
        },
        {
            id: "get-involved",
            name: qsTr("Get Involved"),
            icon: "code",
            component: null
        },
    ]

    readonly property var currentPageData: pages.find(p => p.id === currentPage) ?? pages[0]

    color: Colours.palette.m3background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top navigation bar
        StyledRect {
            id: topNav

            Layout.fillWidth: true
            Layout.preferredHeight: navContent.implicitHeight + Appearance.padding.normal * 2

            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
            radius: 0

            RowLayout {
                id: navContent

                anchors.fill: parent
                anchors.leftMargin: Appearance.padding.large
                anchors.rightMargin: Appearance.padding.large
                anchors.topMargin: Appearance.padding.normal
                anchors.bottomMargin: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                // Logo
                RowLayout {
                    id: logo
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        text: "waving_hand"
                        font.pointSize: Appearance.font.size.large
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: "Caelestia"
                        font.pointSize: Appearance.font.size.large
                        font.bold: true
                        color: Colours.palette.m3onSurface
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Horizontal tab navigation
                Item {
                    Layout.preferredWidth: tabsRow.width
                    Layout.preferredHeight: tabsRow.height

                    StyledRect {
                        id: activeIndicator

                        property Item activeTab: {
                            for (let i = 0; i < tabsRepeater.count; i++) {
                                const tab = tabsRepeater.itemAt(i);
                                if (tab && tab.isActive) {
                                    return tab;
                                }
                            }
                            return null;
                        }

                        visible: activeTab !== null
                        color: Colours.palette.m3primary
                        radius: Appearance.rounding.small

                        x: activeTab ? activeTab.x : 0
                        y: activeTab ? activeTab.y : 0
                        width: activeTab ? activeTab.width : 0
                        height: activeTab ? activeTab.height : 0

                        Behavior on x {
                            Anim {
                                duration: Appearance.anim.durations.normal
                                easing.bezierCurve: Appearance.anim.curves.emphasized
                            }
                        }

                        Behavior on width {
                            Anim {
                                duration: Appearance.anim.durations.normal
                                easing.bezierCurve: Appearance.anim.curves.emphasized
                            }
                        }
                    }

                    Row {
                        id: tabsRow
                        spacing: Appearance.spacing.small

                        Repeater {
                            id: tabsRepeater
                            model: root.pages

                            delegate: Item {
                                required property var modelData
                                required property int index

                                property bool isActive: root.currentPage === modelData.id

                                implicitWidth: tabContent.width + Appearance.padding.normal * 2
                                implicitHeight: tabContent.height + Appearance.padding.smaller * 2

                                StateLayer {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    function onClicked(): void {
                                        root.currentPage = modelData.id;
                                    }
                                }

                                Row {
                                    id: tabContent
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.smaller

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon
                                        font.pointSize: Appearance.font.size.small
                                        color: isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        font.pointSize: Appearance.font.size.small
                                        color: isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: "close"
                    type: IconButton.Text
                    radius: Appearance.rounding.small
                    padding: Appearance.padding.small
                    onClicked: QsWindow.window.destroy()
                }
            }
        }

        // Main content area
        Item {
            id: contentArea

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Appearance.padding.large
            Layout.leftMargin: Appearance.padding.large
            Layout.rightMargin: Appearance.padding.large
            Layout.bottomMargin: Appearance.padding.large
            clip: true

            property string activePage: ""
            property string targetPage: ""
            property bool transitioning: false
            property int direction: 0

            Component.onCompleted: {
                activePage = root.currentPage;
                targetPage = root.currentPage;
                currentPageLoader.sourceComponent = root.currentPageData.component;
            }

            onTargetPageChanged: {
                if (targetPage !== activePage && !transitioning) {
                    const currentIndex = root.pages.findIndex(p => p.id === activePage);
                    const targetIndex = root.pages.findIndex(p => p.id === targetPage);
                    direction = targetIndex > currentIndex ? 1 : -1;

                    nextPageContainer.x = contentArea.width * direction;
                    nextPageLoader.sourceComponent = root.pages.find(p => p.id === targetPage)?.component;
                    transitioning = true;
                }
            }

            Connections {
                target: root
                function onCurrentPageChanged() {
                    contentArea.targetPage = root.currentPage;
                }
            }

            Item {
                id: currentPageContainer
                x: 0
                width: contentArea.width
                height: contentArea.height

                Loader {
                    id: currentPageLoader
                    anchors.fill: parent
                }
            }

            Item {
                id: nextPageContainer
                x: contentArea.width
                width: contentArea.width
                height: contentArea.height

                Loader {
                    id: nextPageLoader
                    anchors.fill: parent
                }
            }

            SequentialAnimation {
                id: slideAnimation
                running: false

                ParallelAnimation {
                    NumberAnimation {
                        target: currentPageContainer
                        property: "x"
                        to: -contentArea.width * contentArea.direction
                        duration: 350
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: nextPageContainer
                        property: "x"
                        to: 0
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

                ScriptAction {
                    script: {
                        currentPageLoader.sourceComponent = nextPageLoader.sourceComponent;
                        currentPageContainer.x = 0;
                        nextPageContainer.x = contentArea.width;
                        contentArea.activePage = contentArea.targetPage;
                        contentArea.transitioning = false;
                    }
                }
            }

            onTransitioningChanged: {
                if (transitioning) {
                    slideAnimation.start();
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
