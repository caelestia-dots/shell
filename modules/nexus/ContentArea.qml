pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus
import qs.modules.nexus.components //qmllint disable unused-imports
import qs.modules.nexus.components.power //qmllint disable unused-imports
import qs.modules.nexus.components.common //qmllint disable unused-imports

Item {
    id: root

    required property NexusSession session

    readonly property var activeConfig: NexusRegistry.getById(session.activeCategory)
    readonly property var tabs: activeConfig ? NexusRegistry.getCategoryTabs(activeConfig.id) : []

    property int activeTabIndex: 0
    property string _prevCategory: ""
    property var _prevConfig: null
    property var _prevTabs: []
    property bool _categoryTransitioning: false
    property real _slideOffset: 0

    function updateTabIndicator() {
        const item = tabRepeater.itemAt(activeTabIndex);
        if (item) {
            tabIndicator.targetX = item.x;
            tabIndicator.targetWidth = item.width;
        } else {
            tabIndicator.targetX = 0;
            tabIndicator.targetWidth = 0;
        }
    }

    function onForcedTabChanged() {
        if (session.forcedTab !== "") {
            const tabList = root.tabs;
            for (let i = 0; i < tabList.length; i++) {
                if (tabList[i] === session.forcedTab) {
                    root.activeTabIndex = i;
                    break;
                }
            }
            session.consumeForcedTab();
        }
    }

    onActiveConfigChanged: {
        if (session.activeCategory === "") {
            _prevCategory = "";
            _prevConfig = null;
            _prevTabs = [];
            activeTabIndex = 0;
            contentContainer.opacity = 0;
            _slideOffset = 0;
            _categoryTransitioning = false;
        } else if (_prevCategory === "") {
            _prevCategory = session.activeCategory;
            _prevConfig = activeConfig;
            _prevTabs = tabs;
            activeTabIndex = 0;
            contentFadeOut.stop();
            contentContainer.opacity = 0;
            _slideOffset = contentContainer.height * 0.15;
            contentFadeIn.restart();
            _categoryTransitioning = false;
        } else {
            _categoryTransitioning = true;
            contentFadeOut.start();
        }
        tabIndicatorUpdate.restart();
    }

    onActiveTabIndexChanged: {
        tabIndicatorUpdate.restart();
    }

    Timer {
        id: tabIndicatorUpdate

        interval: 0
        onTriggered: root.updateTabIndicator()
    }

    Connections {
        function onForcedTabChanged() {
            root.onForcedTabChanged();
        }

        target: root.session
    }

    ParallelAnimation {
        id: contentFadeOut

        onFinished: {
            root._prevCategory = root.session.activeCategory;
            root._prevConfig = root.activeConfig;
            root._prevTabs = root.tabs;
            root.activeTabIndex = 0;
            root._slideOffset = contentContainer.height * 0.15;
            contentFadeIn.start();
        }

        NumberAnimation {
            target: contentContainer
            property: "opacity"
            from: 1
            to: 0
            duration: 150
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: root
            property: "_slideOffset"
            from: 0
            to: -contentContainer.height * 0.15
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }

    ParallelAnimation {
        id: contentFadeIn

        onFinished: {
            root._categoryTransitioning = false;
        }

        NumberAnimation {
            target: contentContainer
            property: "opacity"
            from: 0
            to: 1
            duration: 250
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: root
            property: "_slideOffset"
            from: contentContainer.height * 0.15
            to: 0
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    ColumnLayout {
        id: contentContainer

        anchors.fill: parent
        anchors.margins: Tokens.padding.large * 3
        spacing: Tokens.spacing.normal

        opacity: 1

        transform: Translate {
            y: root._slideOffset // qmllint disable Quick.layout-positioning
        }

        // Header: title + description
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.smaller

            spacing: Tokens.spacing.small / 2

            StyledText {
                text: root._prevConfig?.label ?? ""
                font.pointSize: Tokens.font.size.larger + 4
                font.weight: Font.DemiBold
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: root._prevConfig?.description ?? ""
                font.pointSize: Tokens.font.size.normal
                color: Qt.alpha(Colours.palette.m3onSurface, 0.7)
                visible: root._prevConfig && root._prevConfig.description
            }
        }

        Item {
            id: tabBar

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.smaller
            Layout.bottomMargin: Tokens.spacing.large
            Layout.preferredHeight: 48
            visible: root._prevTabs.length > 0

            // Track line
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -8
                height: 1
                color: Qt.alpha(Colours.palette.m3onSurface, 0.1)
            }

            Row {
                id: tabRow

                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 4

                Repeater {
                    id: tabRepeater

                    model: root._prevTabs

                    delegate: Rectangle {
                        id: tabItem

                        required property string modelData
                        required property int index

                        width: tabLabel.implicitWidth + Tokens.padding.large * 2
                        height: 48
                        radius: Tokens.rounding.small
                        color: "transparent"

                        onXChanged: if (tabItem.index === root.activeTabIndex)
                            tabIndicator.targetX = tabItem.x
                        onWidthChanged: if (tabItem.index === root.activeTabIndex)
                            tabIndicator.targetWidth = tabItem.width

                        StyledText {
                            id: tabLabel

                            anchors.centerIn: parent
                            text: tabItem.modelData
                            font.pointSize: Tokens.font.size.normal
                            font.weight: Font.Medium
                            color: root.activeTabIndex === tabItem.index ? Colours.palette.m3primary : Colours.palette.m3onSurface

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        StateLayer {
                            radius: Tokens.rounding.small
                            color: root.activeTabIndex === tabItem.index ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            onClicked: root.activeTabIndex = tabItem.index
                        }
                    }
                }
            }

            Rectangle {
                id: tabIndicator

                property real targetX: 0
                property real targetWidth: 0

                anchors.bottom: parent.bottom
                anchors.bottomMargin: -8
                height: 3
                radius: 1.5
                color: Colours.palette.m3primary
                visible: root._prevTabs.length > 0

                x: targetX
                width: targetWidth

                Behavior on x {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
                Behavior on width {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
            }
        }

        // Panel content - single loader, panel manages its own tabs
        Loader {
            id: panelLoader

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Tokens.spacing.normal

            readonly property string panelId: root._prevConfig ? root._prevConfig.id.charAt(0).toUpperCase() + root._prevConfig.id.slice(1) : ""
            readonly property string targetSource: panelId ? "panels/" + panelId + "/Main.qml" : ""
            property string resolvedSource: targetSource

            asynchronous: true
            source: resolvedSource

            onTargetSourceChanged: resolvedSource = targetSource

            onStatusChanged: {
                if (status === Loader.Error && resolvedSource !== "panels/PlaceholderPanel.qml") {
                    Qt.callLater(() => {
                        resolvedSource = "panels/PlaceholderPanel.qml";
                    });
                }
            }

            Binding {
                target: panelLoader.item
                property: "activeTabIndex"
                value: root.activeTabIndex
                when: panelLoader.item && panelLoader.item.hasOwnProperty("activeTabIndex")
            }
        }
    }
}
