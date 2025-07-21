pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property real nonAnimWidth
    required property PersistentProperties state
    readonly property alias count: bar.count

    implicitHeight: bar.implicitHeight + indicator.implicitHeight + indicator.anchors.topMargin + separator.implicitHeight

    TabBar {
        id: bar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        currentIndex: root.state.currentTab
        background: null

        Tab {
            iconName: "dashboard"
            text: qsTr("Dashboard")
        }

        Tab {
            iconName: "queue_music"
            text: qsTr("Media")
        }

        Tab {
            iconName: "speed"
            text: qsTr("Performance")
        }

        // Tab {
        //     iconName: "workspaces"
        //     text: qsTr("Workspaces")
        // }
    }

    Item {
        id: indicator

        anchors.top: bar.bottom
        anchors.topMargin: Config.dashboard.sizes.tabIndicatorSpacing

        implicitWidth: bar.currentItem.implicitWidth
        implicitHeight: Config.dashboard.sizes.tabIndicatorHeight

        x: {
            const tab = bar.currentItem;
            const width = (root.nonAnimWidth - bar.spacing * (bar.count - 1)) / bar.count;
            return width * tab.TabBar.index + (width - tab.implicitWidth) / 2;
        }

        clip: true

        StyledRect {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: parent.implicitHeight * 2

            color: Colours.palette.m3primary
            radius: Appearance.rounding.full
        }

        Behavior on x {
            Anim {}
        }

        Behavior on implicitWidth {
            Anim {}
        }
    }

    StyledRect {
        id: separator

        anchors.top: indicator.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }

    component Tab: TabButton {
        id: tab

        required property string iconName
        readonly property bool current: TabBar.tabBar.currentItem === this

        background: null

        contentItem: CustomMouseArea {
            id: mouse

            implicitWidth: Math.max(icon.width, label.width)
            implicitHeight: icon.height + label.height

            cursorShape: Qt.PointingHandCursor

            onPressed: event => {
                root.state.currentTab = tab.TabBar.index;

                const stateY = stateWrapper.y;
                rippleAnim.x = event.x;
                rippleAnim.y = event.y - stateY;

                const dist = (ox, oy) => ox * ox + oy * oy;
                rippleAnim.radius = Math.sqrt(Math.max(dist(event.x, event.y + stateY), dist(event.x, stateWrapper.height - event.y), dist(width - event.x, event.y + stateY), dist(width - event.x, stateWrapper.height - event.y)));

                rippleAnim.restart();
            }

            function onWheel(event: WheelEvent): void {
                if (event.angleDelta.y < 0)
                    root.state.currentTab = Math.min(root.state.currentTab + 1, bar.count - 1);
                else if (event.angleDelta.y > 0)
                    root.state.currentTab = Math.max(root.state.currentTab - 1, 0);
            }

            SequentialAnimation {
                id: rippleAnim

                property real x
                property real y
                property real radius

                PropertyAction {
                    target: ripple
                    property: "x"
                    value: rippleAnim.x
                }
                PropertyAction {
                    target: ripple
                    property: "y"
                    value: rippleAnim.y
                }
                PropertyAction {
                    target: ripple
                    property: "opacity"
                    value: 0.08
                }
                Anim {
                    target: ripple
                    properties: "implicitWidth,implicitHeight"
                    from: 0
                    to: rippleAnim.radius * 2
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    target: ripple
                    property: "opacity"
                    to: 0
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }

            ClippingRectangle {
                id: stateWrapper

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height + Config.dashboard.sizes.tabIndicatorSpacing * 2

                color: "transparent"
                radius: Appearance.rounding.small

                StyledRect {
                    id: stateLayer

                    anchors.fill: parent

                    color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    opacity: mouse.pressed ? 0.1 : tab.hovered ? 0.08 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }

                StyledRect {
                    id: ripple

                    radius: Appearance.rounding.full
                    color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    opacity: 0

                    transform: Translate {
                        x: -ripple.width / 2
                        y: -ripple.height / 2
                    }
                }
            }

            MaterialIcon {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: label.top

                text: tab.iconName
                color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fill: tab.current ? 1 : 0
                font.pointSize: Appearance.font.size.large

                Behavior on fill {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }

            StyledText {
                id: label

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                text: tab.text
                color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
