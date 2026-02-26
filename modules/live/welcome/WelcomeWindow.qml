pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.containers
import qs.components.controls
import qs.config
import qs.services
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
            id: "getting-started",
            name: qsTr("Getting Started"),
            icon: "rocket_launch",
            component: gettingStartedComponent
        },
        {
            id: "tour",
            name: qsTr("Tour"),
            icon: "planet",
            component: tourComponent
        },
        {
            id: "configuration",
            name: qsTr("Configuration"),
            icon: "settings",
            component: configurationComponent
        },
        {
            id: "faqs",
            name: qsTr("FAQs"),
            icon: "help",
            component: faqsComponent
        },
        {
            id: "community",
            name: qsTr("Community"),
            icon: "people",
            component: communityComponent
        },
    ]

    readonly property var currentPageData: pages.find(p => p.id === currentPage) ?? pages[0]

    color: Colours.palette.m3background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0


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


                RowLayout {
                    id: logo
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: "Caelestia"
                        font.pointSize: Appearance.font.size.large
                        font.bold: true
                        color: Colours.palette.m3onSurface
                    }
                }

                IconButton {
                    icon: "chevron_left"
                    visible: tabsFlickable.contentWidth > tabsFlickable.width
                    type: IconButton.Text
                    radius: Appearance.rounding.small
                    padding: Appearance.padding.small
                    onClicked: {
                        tabsFlickable.contentX = Math.max(0, tabsFlickable.contentX - 100);
                    }
                }

                StyledFlickable {
                    id: tabsFlickable
                    Layout.fillWidth: true
                    Layout.preferredHeight: tabsRow.height
                    flickableDirection: Flickable.HorizontalFlick
                    contentWidth: tabsRow.width
                    clip: true

                    Behavior on contentX {
                        Anim {
                            duration: Appearance.anim.durations.normal
                            easing.bezierCurve: Appearance.anim.curves.emphasized
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true

                        onWheel: wheel => {
                            const delta = wheel.angleDelta.y || wheel.angleDelta.x;
                            tabsFlickable.contentX = Math.max(0, Math.min(tabsFlickable.contentWidth - tabsFlickable.width, tabsFlickable.contentX - delta));
                            wheel.accepted = true;
                        }

                        onPressed: mouse => {
                            mouse.accepted = false;
                        }
                    }

                    Item {
                        implicitWidth: tabsRow.width
                        implicitHeight: tabsRow.height

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
                                    id: tabsItem

                                    required property var modelData
                                    required property int index

                                    property bool isActive: root.currentPage === modelData.id

                                    implicitWidth: tabContent.width + Appearance.padding.normal * 2
                                    implicitHeight: tabContent.height + Appearance.padding.smaller * 2

                                    StateLayer {
                                        anchors.fill: parent
                                        radius: Appearance.rounding.small
                                        function onClicked(): void {
                                            root.currentPage = tabsItem.modelData.id;

                                            const tabLeft = parent.x;
                                            const tabRight = parent.x + parent.width;
                                            const viewLeft = tabsFlickable.contentX;
                                            const viewRight = tabsFlickable.contentX + tabsFlickable.width;

                                            const targetX = tabLeft - (tabsFlickable.width - parent.width) / 2;

                                            tabsFlickable.contentX = Math.max(0, Math.min(tabsFlickable.contentWidth - tabsFlickable.width, targetX));
                                        }
                                    }

                                    Row {
                                        id: tabContent
                                        anchors.centerIn: parent
                                        spacing: Appearance.spacing.smaller

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: tabsItem.modelData.icon
                                            font.pointSize: Appearance.font.size.small
                                            fill: 1
                                            color: tabsItem.isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                        }

                                        StyledText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: tabsItem.modelData.name
                                            font.pointSize: Appearance.font.size.small
                                            color: tabsItem.isActive ? Colours.palette.m3surface : Colours.palette.m3onSurfaceVariant
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                IconButton {
                    icon: "chevron_right"
                    visible: tabsFlickable.contentWidth > tabsFlickable.width
                    type: IconButton.Text
                    radius: Appearance.rounding.small
                    padding: Appearance.padding.small
                    onClicked: {
                        tabsFlickable.contentX = Math.min(tabsFlickable.contentWidth - tabsFlickable.width, tabsFlickable.contentX + 100);
                    }
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

    Component {
        id:tourComponent
        Tour{}
    }

    Component {
        id: configurationComponent
        Configuration {}
    }

    Component {
        id: faqsComponent
        FAQs {}
    }

    Component {
        id: communityComponent
        Community {}
    }
    //Component {
        //id: installComponent
        //Install {}
    //}
}
