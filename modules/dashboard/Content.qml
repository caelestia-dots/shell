pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property PersistentProperties visibilities
    required property PersistentProperties state
    required property FileDialog facePicker
    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2
    readonly property real nonAnimHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    onImplicitWidthChanged: {
        if (root.state.currentTab >= tabs.count) {
            root.state.currentTab = 0;
        }
    }

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Appearance.padding.normal
        anchors.margins: Appearance.padding.large

        nonAnimWidth: root.nonAnimWidth - anchors.margins * 2
        state: root.state
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.padding.large

        radius: Appearance.rounding.normal
        color: "transparent"

        Flickable {
            id: view

            readonly property int currentIndex: root.state.currentTab
            readonly property Item currentItem: row.children[currentIndex]

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: currentItem.implicitWidth
            implicitHeight: currentItem.implicitHeight

            contentX: currentItem.x
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 2)
                    root.state.currentTab = Math.min(root.state.currentTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 2)
                    root.state.currentTab = Math.max(root.state.currentTab - 1, 0);
            }

            onDragEnded: {
                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 10)
                    root.state.currentTab = Math.min(root.state.currentTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 10)
                    root.state.currentTab = Math.max(root.state.currentTab - 1, 0);
                else
                    contentX = Qt.binding(() => currentItem.x);
            }

            RowLayout {
                id: row

                Repeater {
                    model: {
                        const allPanes = [
                            { index: 0, component: "dash" },
                            { index: 1, component: "media" },
                            { index: 2, component: "performance", enabled: Config.dashboard.performance.showCpu || Config.dashboard.performance.showGpu || Config.dashboard.performance.showMemory || Config.dashboard.performance.showStorage || Config.dashboard.performance.showNetwork || Config.dashboard.performance.showBattery },
                            { index: 3, component: "weather" }
                        ];
                        return allPanes.filter(pane => pane.enabled !== false);
                    }

                    delegate: Loader {
                        id: paneLoader
                        
                        required property int index
                        required property var modelData
                        
                        Layout.alignment: Qt.AlignTop
                        
                        sourceComponent: {
                            switch (modelData.component) {
                                case "dash": return dashComponent;
                                case "media": return mediaComponent;
                                case "performance": return performanceComponent;
                                case "weather": return weatherComponent;
                                default: return null;
                            }
                        }
                        
                        Component.onCompleted: active = Qt.binding(() => {
                            if (index === view.currentIndex)
                                return true;
                            const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
                            const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
                            return (vx >= x && vx <= x + implicitWidth) || (vex >= x && vex <= x + implicitWidth);
                        })
                    }
                }
            }
            
            Component {
                id: dashComponent
                Dash {
                    visibilities: root.visibilities
                    state: root.state
                    facePicker: root.facePicker
                }
            }
            
            Component {
                id: mediaComponent
                Media {
                    visibilities: root.visibilities
                }
            }
            
            Component {
                id: performanceComponent
                Performance {}
            }
            
            Component {
                id: weatherComponent
                Weather {}
            }

            Behavior on contentX {
                Anim {}
            }
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }
}
