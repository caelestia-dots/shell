pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property real nonAnimMargin: handler.hovered ? Appearance.padding.large * 1.5 : Appearance.padding.large
    readonly property real nonAnimWidth: handler.hovered ? Config.lock.sizes.buttonsWidth : Config.lock.sizes.buttonsWidthSmall
    readonly property real nonAnimHeight: (nonAnimWidth + nonAnimMargin * 2) / 4

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.anim.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    HoverHandler {
        id: handler

        target: parent
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.nonAnimMargin
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        spacing: Appearance.spacing.normal

        SessionButton {
            icon: "logout"
            command: ["loginctl", "terminate-user", ""]
        }

        SessionButton {
            icon: "power_settings_new"
            command: ["systemctl", "poweroff"]
        }

        SessionButton {
            icon: "downloading"
            command: ["systemctl", "hibernate"]
        }

        SessionButton {
            icon: "cached"
            command: ["systemctl", "reboot"]
        }

        Behavior on anchors.margins {
            NumberAnimation {
                duration: Appearance.anim.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    }

    component SessionButton: StyledRect {
        required property string icon
        required property list<string> command

        Layout.fillWidth: true
        Layout.preferredHeight: width

        radius: Appearance.rounding.large * 1.2
        color: Colours.palette.m3secondaryContainer

        StateLayer {
            id: stateLayer

            color: Colours.palette.m3onSecondaryContainer

            function onClicked(): void {
                Quickshell.execDetached(parent.command);
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: parent.icon
            color: Colours.palette.m3onSecondaryContainer
            font.pointSize: (parent.width * 0.4) || 1
            font.weight: handler.hovered ? 500 : 400
        }
    }
}
