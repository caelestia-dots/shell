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

    readonly property bool showTabs: Config.dashboard.enableMedia || Config.dashboard.enablePerformance

    required property PersistentProperties visibilities
    required property PersistentProperties state
    required property FileDialog facePicker
    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2
    readonly property real nonAnimHeight: (showTabs ? tabs.implicitHeight + tabs.anchors.topMargin : 0) + view.implicitHeight + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Loader {
        id: tabs
        asynchronous: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Appearance.padding.normal
        anchors.margins: Appearance.padding.large

        sourceComponent: root.showTabs ? tabsComponent : null
    }

    Component {
        id: tabsComponent
        Tabs {
            nonAnimWidth: root.nonAnimWidth - parent.anchors.margins * 2
            state: root.state
        }
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: root.showTabs ? tabs.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: !root.showTabs ? Appearance.padding.normal : Appearance.padding.large
        anchors.margins: Appearance.padding.large

        radius: Appearance.rounding.normal
        color: "transparent"

        Flickable {
            id: view

            readonly property int currentIndex: root.state.currentTab
            readonly property Item currentItem: panelGenerator.count > 0 ? panelGenerator.itemAt(currentIndex) : null
            property list<Component> panelModel: [dash, Config.dashboard.enableMedia ? media : null, Config.dashboard.enablePerformance ? performance : null, Config.dashboard.enableWeather ? weather : null].filter(panel => panel != null)

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            Component {
                id: dash
                Dash {
                    visibilities: root.visibilities
                    state: root.state
                    facePicker: root.facePicker
                }
            }

            Component {
                id: media
                Media {
                    visibilities: root.visibilities
                }
            }

            Component {
                id: performance
                Performance {}
            }

            Component {
                id: weather
                Weather {}
            }

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

            onPanelModelChanged: {
                panelGenerator.model = panelModel;
            }

            RowLayout {
                id: row

                Repeater {
                    id: panelGenerator
                    delegate: Pane {
                        required property Component modelData
                        sourceComponent: modelData
                    }
                }
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

    component Pane: Loader {
        id: pane

        required property int index

        Layout.alignment: Qt.AlignTop

        Component.onCompleted: active = Qt.binding(() => {
            // Always keep current tab loaded
            if (pane.index === view.currentIndex)
                return true;
            const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
            const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
            return (vx >= x && vx <= x + implicitWidth) || (vex >= x && vex <= x + implicitWidth);
        })
    }
}
