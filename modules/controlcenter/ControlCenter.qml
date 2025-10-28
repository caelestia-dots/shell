pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    readonly property int rounding: floating ? 0 : Appearance.rounding.normal

    property alias floating: session.floating
    property alias active: session.active
    property alias navExpanded: session.navExpanded

    readonly property Session session: Session {
        id: session

        root: root
    }

    function close(): void {
    }

    implicitWidth: implicitHeight * Config.controlCenter.sizes.ratio
    implicitHeight: screen.height * Config.controlCenter.sizes.heightMult

    GridLayout {
        anchors.fill: parent

        rowSpacing: 0
        columnSpacing: 0
        rows: root.floating ? 2 : 1
        columns: 2

        Loader {
            Layout.fillWidth: true
            Layout.columnSpan: 2

            asynchronous: true
            active: root.floating
            visible: active

            sourceComponent: WindowTitle {
                screen: root.screen
                session: root.session
            }
        }

        StyledRect {
            Layout.fillHeight: true

            topLeftRadius: root.rounding
            bottomLeftRadius: root.rounding
            implicitWidth: navRail.implicitWidth
            color: Colours.tPalette.m3surfaceContainer

            CustomMouseArea {
                anchors.fill: parent

                function onWheel(event: WheelEvent): void {
                    if (event.angleDelta.y < 0)
                        root.session.activeIndex = Math.min(root.session.activeIndex + 1, root.session.panes.length - 1);
                    else if (event.angleDelta.y > 0)
                        root.session.activeIndex = Math.max(root.session.activeIndex - 1, 0);
                }
            }

            NavRail {
                id: navRail

                screen: root.screen
                session: root.session
            }
        }

        Panes {
            Layout.fillWidth: true
            Layout.fillHeight: true

            topRightRadius: root.rounding
            bottomRightRadius: root.rounding
            session: root.session
        }
    }
}
