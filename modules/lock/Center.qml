import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock
    required property real lockHeight
    property bool isPortrait: false

    readonly property real centerScale: Math.min(1, root.lockHeight / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    Layout.preferredWidth: isPortrait ? -1 : centerWidth
    Layout.fillWidth: isPortrait
    Layout.fillHeight: true

    spacing: Tokens.spacing.largeIncreased

    // Portrait: profile picture on the left, clock + date stacked on the right.
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.padding.large
        visible: root.isPortrait
        spacing: Tokens.spacing.largeIncreased

        ProfilePic {
            Layout.alignment: Qt.AlignVCenter
            centerWidth: root.centerWidth
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.small

            Clock {
                centerScale: root.centerScale
            }

            StyledText {
                text: Time.format("dddd • d MMM").toUpperCase()
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
            }
        }
    }

    // Landscape: clock, date and profile picture stacked vertically (unchanged).
    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.padding.large
        visible: !root.isPortrait
        centerScale: root.centerScale
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        visible: !root.isPortrait

        text: Time.format("dddd • d MMM").toUpperCase()
        color: Colours.palette.m3onSurface
        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.extraExtraLarge * root.centerScale
        Layout.bottomMargin: Tokens.spacing.extraLarge * root.centerScale
        visible: !root.isPortrait
        centerWidth: root.centerWidth
    }

    PasswordInput {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: root.isPortrait ? Tokens.spacing.large : 0
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        lock: root.lock
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }
}
