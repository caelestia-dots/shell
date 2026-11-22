pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property HyprlandToplevel client

    Layout.preferredWidth: preview.implicitWidth + Tokens.padding.extraLargeIncreased
    Layout.fillHeight: true

    ClipRect {
        id: preview

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: label.top
        anchors.topMargin: Tokens.padding.large
        anchors.bottomMargin: Tokens.spacing.medium

        implicitWidth: view.implicitWidth

        color: Hallownest.card
        radius: 14

        Rectangle {
            anchors.fill: parent
            z: 2
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Hallownest.border
        }

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: !root.client

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.small

                Mask {
                    Layout.alignment: Qt.AlignHCenter
                    size: 72
                    filled: false
                    colour: Hallownest.steel
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("No active client")
                    color: Hallownest.soul
                    font.family: Hallownest.serif
                    font.pointSize: 16
                    font.weight: Font.Bold
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("Try switching to a window")
                    color: Hallownest.subtext
                    font: Tokens.font.body.medium
                }
            }
        }

        ScreencopyView {
            id: view

            anchors.centerIn: parent

            captureSource: root.client?.wayland ?? null
            live: true

            constraintSize.width: root.client ? parent.height * Math.min(root.screen.width / root.screen.height, root.client?.lastIpcObject.size[0] / root.client?.lastIpcObject.size[1]) : parent.height
            constraintSize.height: parent.height
        }
    }

    StyledText {
        id: label

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.large

        animate: true
        text: {
            const client = root.client;
            if (!client)
                return Tr.tr("No active client");

            const mon = client.monitor;
            // TRANSLATORS: %1 = window title, %2 = monitor name, %3/%4 = x/y position in pixels
            return Tr.tr("%1 on monitor %2 at %3, %4").arg(client.title).arg(mon.name).arg(client.lastIpcObject.at[0]).arg(client.lastIpcObject.at[1]);
        }
    }
}
