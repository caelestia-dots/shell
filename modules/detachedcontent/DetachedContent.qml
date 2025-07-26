pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    required property ShellScreen screen
    property alias active: session.active
    readonly property Session session: Session {
        id: session
    }

    implicitWidth: implicitHeight * Config.dcontent.sizes.ratio
    implicitHeight: screen.height * Config.dcontent.sizes.heightMult

    GridLayout {
        anchors.fill: parent

        rows: 2
        columns: 2
        rowSpacing: 0
        columnSpacing: 0

        StyledRect {
            Layout.fillHeight: true
            Layout.rowSpan: 2

            topLeftRadius: Appearance.rounding.normal
            bottomLeftRadius: Appearance.rounding.normal
            implicitWidth: navRail.implicitWidth
            color: Colours.palette.m3surfaceContainer

            NavRail {
                id: navRail

                session: root.session
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 50
            topRightRadius: Appearance.rounding.normal
            color: Colours.palette.m3surfaceContainer
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledText {
                anchors.centerIn: parent
                text: qsTr("Work in progress")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.extraLarge
                font.weight: 500
            }

            StyledRect {
                anchors.fill: parent
                color: Colours.palette.m3surfaceContainer
                bottomRightRadius: Appearance.rounding.normal

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskSource: mask
                    maskEnabled: true
                    maskInverted: true
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
            }

            Item {
                id: mask

                anchors.fill: parent
                layer.enabled: true
                visible: false

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    anchors.topMargin: 0
                    anchors.leftMargin: 0
                    radius: Appearance.rounding.small
                }
            }
        }
    }
}
