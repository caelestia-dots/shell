pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.components.filedialog
import qs.config

Item {
    id: root

    required property DrawerVisibilities visibilities
    readonly property bool needsKeyboard: {
        const count = repeater.count;
        for (let i = 0; i < count; i++) {
            const item = repeater.itemAt(i) as Loader;
            if (item?.sourceComponent === mediaComponent && (item?.item as MediaWrapper)?.needsKeyboard)
                return true;
        }
        return false;
    }
    required property DashboardState state
    required property FileDialog facePicker

    readonly property var dashboardTabs: {
        const allTabs = [
            {
                component: dashComponent,
                iconName: "dashboard",
                text: qsTr("Dashboard"),
                enabled: Config.dashboard.showDashboard
            },
            {
                component: mediaComponent,
                iconName: "queue_music",
                text: qsTr("Media"),
                enabled: Config.dashboard.showMedia
            },
            {
                component: performanceComponent,
                iconName: "speed",
                text: qsTr("Performance"),
                enabled: Config.dashboard.showPerformance && (Config.dashboard.performance.showCpu || Config.dashboard.performance.showGpu || Config.dashboard.performance.showMemory || Config.dashboard.performance.showStorage || Config.dashboard.performance.showNetwork || Config.dashboard.performance.showBattery)
            },
            {
                component: weatherComponent,
                iconName: "cloud",
                text: qsTr("Weather"),
                enabled: Config.dashboard.showWeather
            }
        ];
        return allTabs.filter(tab => tab.enabled);
    }

    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2
    readonly property real nonAnimHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Appearance.padding.normal
        anchors.margins: Appearance.padding.large

        nonAnimWidth: root.nonAnimWidth - anchors.margins * 2
        state: root.state
        tabs: root.dashboardTabs
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
            readonly property Item currentItem: {
                repeater.count; // Trigger update on count change
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving || !currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 2)
                    root.state.currentTab = Math.min(root.state.currentTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 2)
                    root.state.currentTab = Math.max(root.state.currentTab - 1, 0);
            }

            onDragEnded: {
                if (!currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 10)
                    root.state.currentTab = Math.min(root.state.currentTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 10)
                    root.state.currentTab = Math.max(root.state.currentTab - 1, 0);
                else
                    contentX = Qt.binding(() => currentItem?.x ?? 0);
            }

            RowLayout {
                id: row

                Repeater {
                    id: repeater

                    model: ScriptModel {
                        values: root.dashboardTabs
                    }

                    delegate: Loader {
                        id: paneLoader

                        required property int index
                        required property var modelData

                        Layout.alignment: Qt.AlignTop

                        sourceComponent: modelData.component

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

                MediaWrapper {
                    visibilities: root.visibilities
                }
            }

            Component {
                id: performanceComponent

                Performance {}
            }

            Component {
                id: weatherComponent

                WeatherTab {}
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
