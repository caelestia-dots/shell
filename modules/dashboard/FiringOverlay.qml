pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities

    readonly property bool isReminder: ReminderService.reminderFired && !TimerService.timerDone && !AlarmService.alarmFired

    function dismiss(): void {
        TimerService.timerDone = false;
        AlarmService.alarmFired = false;
        ReminderService.dismissCurrent();
        root.visibilities.fireOverlay = false;
        root.visibilities.dashboard = false;
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing.normal

        AnimatedImage {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 300
            Layout.preferredHeight: 220

            source: Paths.absolutePath(GlobalConfig.paths.mediaGif)
            speed: 2.0
            playing: true
            fillMode: AnimatedImage.PreserveAspectFit
            asynchronous: true
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.isReminder ? ReminderService.currentReminderText : qsTr("Your time is up!")
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 600
            horizontalAlignment: Text.AlignHCenter
            color: Colours.palette.m3onSurface
        }

        IconTextButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: 200
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.normal
            text: qsTr("Dismiss")
            icon: "check"
            onClicked: root.dismiss()
        }
    }
}
