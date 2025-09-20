pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell

Item {
    id: root
    property var wrapper  // not required for standalone popout

    implicitWidth: layout.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2

    ColumnLayout {
        id: layout
        anchors.fill: parent

        // Display current keyboard layout
        StyledText {
            id: kbLayoutText
            text: qsTr("Keyboard layout: %1").arg(Hypr.kbLayoutFull)
            font.weight: 500
        }

        // Timer to refresh layout after switching
        Timer {
            id: refreshTimer
            interval: 300
            repeat: false
            onTriggered: {
                kbLayoutText.text = qsTr("Keyboard layout: %1").arg(Hypr.kbLayoutFull)
            }
        }

            // Switch Layout button
            StyledRect {
            Layout.topMargin: Appearance.spacing.small
            Layout.fillWidth: true

            implicitWidth: switchBtn.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: switchBtn.implicitHeight + Appearance.padding.small

            radius: Appearance.rounding.normal
            color: Colours.palette.m3primaryContainer

            StateLayer {
                color: Colours.palette.m3onPrimaryContainer

                function onClicked() {
                    Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
                    refreshTimer.start();
                }
            }

            RowLayout {
                id: switchBtn
                anchors.centerIn: parent

                StyledText {
                    text: qsTr("Switch Layout")
                    color: Colours.palette.m3onPrimaryContainer
                    font.weight: 500
                    anchors.centerIn: parent
                }
            }
        }
    }
}
