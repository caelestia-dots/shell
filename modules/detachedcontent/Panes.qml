pragma ComponentBehavior: Bound

import "bluetooth"
import qs.components
import qs.components.effects
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ClippingRectangle {
    id: root

    required property Session session

    topRightRadius: Appearance.rounding.normal
    bottomRightRadius: Appearance.rounding.normal
    color: "transparent"

    ColumnLayout {
        id: layout

        spacing: 0
        y: -root.session.activeIndex * root.height

        Pane {
            index: 0
            sourceComponent: Item {
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Work in progress")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }
            }
        }

        Pane {
            index: 1
            sourceComponent: BtPane {
                session: root.session
            }
        }

        Pane {
            index: 2
            sourceComponent: Item {
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Work in progress")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: 500
                }
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    InnerBorder {
        leftThickness: 0
    }

    component Pane: Item {
        id: pane

        required property int index
        property alias sourceComponent: loader.sourceComponent

        implicitWidth: root.width
        implicitHeight: root.height

        Loader {
            id: loader

            anchors.fill: parent
            clip: true
            asynchronous: true
            active: {
                if (root.session.activeIndex === pane.index)
                    return true;

                const ly = -layout.y;
                const ty = pane.index * root.height;
                return ly + root.height > ty && ly < ty + root.height;
            }
        }
    }
}
