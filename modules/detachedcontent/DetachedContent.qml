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
    property alias active: session.active
    readonly property Session session: Session {
        id: session
    }

    implicitWidth: implicitHeight * Config.dcontent.sizes.ratio
    implicitHeight: screen.height * Config.dcontent.sizes.heightMult

    RowLayout {
        anchors.fill: parent

        spacing: 0

        StyledRect {
            Layout.fillHeight: true

            topLeftRadius: Appearance.rounding.normal
            bottomLeftRadius: Appearance.rounding.normal
            implicitWidth: navRail.implicitWidth
            color: Colours.palette.m3surfaceContainer

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

                session: root.session
            }
        }

        Panes {
            Layout.fillWidth: true
            Layout.fillHeight: true

            session: root.session
        }
    }
}
