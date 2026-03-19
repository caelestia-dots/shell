pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var categories
    required property string activeCategory
    property bool showScrollButtons: true
    property bool showExtraContent: false
    property Component extraContent: null

    signal categoryChanged(string categoryId)

    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
    radius: Appearance.rounding.normal

    visible: opacity > 0
    implicitHeight: tabsRow.height + Appearance.padding.small + Appearance.padding.normal
    clip: true

    function scrollToActiveTab(): void {
        Qt.callLater(() => {
            if (!tabsFlickable || !tabsRow)
                return;

            const currentIndex = root.categories.findIndex(cat => cat.id === root.activeCategory);
            if (currentIndex === -1)
                return;

            let tabX = 0;
            for (let i = 0; i < currentIndex && i < tabsRow.children.length; i++) {
                const child = tabsRow.children[i];
                if (child) {
                    tabX += child.width + tabsRow.spacing;
                }
            }

            const activeTab = tabsRow.children[currentIndex];
            if (!activeTab)
                return;

            const tabWidth = activeTab.width;
            const viewportStart = tabsFlickable.contentX;
            const viewportEnd = tabsFlickable.contentX + tabsFlickable.width;

            if (tabX < viewportStart) {
                tabsFlickable.contentX = tabX;
            } else if (tabX + tabWidth > viewportEnd) {
                tabsFlickable.contentX = Math.min(tabsFlickable.contentWidth - tabsFlickable.width, tabX + tabWidth - tabsFlickable.width);
            }
        });
    }

    RowLayout {
        id: tabsContent
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        anchors.topMargin: Appearance.padding.small
        anchors.bottomMargin: Appearance.padding.smaller
        spacing: Appearance.spacing.smaller

        IconButton {
            icon: "chevron_left"
            visible: root.showScrollButtons && tabsFlickable.contentWidth > tabsFlickable.width
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
                    radius: 10

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
                        model: root.categories

                        delegate: Item {
                            required property var modelData
                            required property int index

                            property bool isActive: root.activeCategory === modelData.id

                            implicitWidth: tabContent.width + Appearance.padding.normal * 2
                            implicitHeight: tabContent.height + Appearance.padding.smaller * 2

                            StateLayer {
                                anchors.fill: parent
                                radius: 6
                                function onClicked(): void {
                                    root.categoryChanged(modelData.id);

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
        }

        IconButton {
            icon: "chevron_right"
            visible: root.showScrollButtons && tabsFlickable.contentWidth > tabsFlickable.width
            type: IconButton.Text
            radius: Appearance.rounding.small
            padding: Appearance.padding.small
            onClicked: {
                tabsFlickable.contentX = Math.min(tabsFlickable.contentWidth - tabsFlickable.width, tabsFlickable.contentX + 100);
            }
        }

        Loader {
            Layout.fillHeight: true
            active: root.showExtraContent && root.extraContent !== null
            sourceComponent: root.extraContent
        }
    }
}
