pragma ComponentBehavior: Bound

import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property int value
    property real max: Infinity
    property real min: -Infinity
    property alias repeatRate: timer.interval

    signal valueModified(value: int)

    spacing: Appearance.spacing.small

    StyledTextField {
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        text: root.value
        onAccepted: root.valueModified(text)

        padding: Appearance.padding.small
        leftPadding: Appearance.padding.normal
        rightPadding: Appearance.padding.normal

        background: StyledRect {
            implicitWidth: 100
            radius: Appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh
        }
    }

    StyledRect {
        radius: Appearance.rounding.small
        color: Colours.palette.m3primary

        implicitWidth: implicitHeight
        implicitHeight: upIcon.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            id: upState

            color: Colours.palette.m3onPrimary

            onPressAndHold: timer.start()
            onReleased: timer.stop()

            function onClicked(): void {
                root.valueModified(Math.min(root.max, root.value + 1));
            }
        }

        MaterialIcon {
            id: upIcon

            anchors.centerIn: parent
            text: "keyboard_arrow_up"
            color: Colours.palette.m3onPrimary
        }
    }

    StyledRect {
        radius: Appearance.rounding.small
        color: Colours.palette.m3primary

        implicitWidth: implicitHeight
        implicitHeight: downIcon.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            id: downState

            color: Colours.palette.m3onPrimary

            onPressAndHold: timer.start()
            onReleased: timer.stop()

            function onClicked(): void {
                root.valueModified(Math.max(root.min, root.value - 1));
            }
        }

        MaterialIcon {
            id: downIcon

            anchors.centerIn: parent
            text: "keyboard_arrow_down"
            color: Colours.palette.m3onPrimary
        }
    }

    Timer {
        id: timer

        interval: 100
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (upState.pressed)
                upState.onClicked();
            else if (downState.pressed)
                downState.onClicked();
        }
    }
}
