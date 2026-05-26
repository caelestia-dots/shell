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

    required property PopoutState popouts

    property int hours: 0
    property int minutes: 0
    property int seconds: 0

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.topMargin: Tokens.padding.normal
            Layout.rightMargin: Tokens.padding.small

            MaterialIcon {
                text: "timer"
                color: Colours.palette.m3tertiary
            }

            StyledText {
                Layout.fillWidth: true
                text: TimerService.timerDone ? qsTr("Your time is up!") : qsTr("Timer")
                font.weight: 500
                color: Colours.palette.m3onSurface
            }
        }

        // Timer done: Bongo Cat
        ColumnLayout {
            visible: TimerService.timerDone
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            AnimatedImage {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 180
                Layout.preferredHeight: 140

                source: Paths.absolutePath(GlobalConfig.paths.mediaGif)
                speed: 2.0
                playing: TimerService.timerDone
                fillMode: AnimatedImage.PreserveAspectFit
                asynchronous: true
            }

            IconTextButton {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.rightMargin: Tokens.padding.small
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                verticalPadding: Tokens.padding.small
                text: qsTr("Dismiss")
                icon: "close"
                onClicked: {
                    TimerService.timerDone = false;
                }
            }
        }

        // Idle: set timer
        ColumnLayout {
            visible: !TimerService.active && !TimerService.timerDone
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small

                SpinGroup {
                    label: qsTr("H")
                    max: 23
                    value: root.hours
                    onValueModified: v => {
                        root.hours = v;
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: ":"
                    font.pointSize: Tokens.font.size.larger
                    font.family: Tokens.font.family.mono
                    color: Colours.palette.m3onSurfaceVariant
                }

                SpinGroup {
                    label: qsTr("M")
                    max: 59
                    value: root.minutes
                    onValueModified: v => {
                        root.minutes = v;
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: ":"
                    font.pointSize: Tokens.font.size.larger
                    font.family: Tokens.font.family.mono
                    color: Colours.palette.m3onSurfaceVariant
                }

                SpinGroup {
                    label: qsTr("S")
                    max: 59
                    value: root.seconds
                    onValueModified: v => {
                        root.seconds = v;
                    }
                }
            }

            IconTextButton {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.rightMargin: Tokens.padding.small
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                verticalPadding: Tokens.padding.small
                text: qsTr("Start")
                icon: "play_arrow"
                onClicked: TimerService.start(root.hours, root.minutes, root.seconds)
            }
        }

        // Active: running/paused
        ColumnLayout {
            visible: TimerService.active && !TimerService.timerDone
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.padding.small
                text: TimerService.remainingFormatted
                font.pointSize: Tokens.font.size.extraLarge
                font.family: Tokens.font.family.mono
                font.weight: 500
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.rightMargin: Tokens.padding.small
                implicitHeight: 4

                StyledRect {
                    width: parent.width
                    height: parent.height
                    radius: 2
                    color: Colours.tPalette.m3surfaceContainerHigh
                }

                StyledRect {
                    width: Math.max(radius * 2, TimerService.progress * parent.width)
                    height: parent.height
                    radius: 2
                    color: Colours.palette.m3primary

                    Behavior on width {
                        Anim {}
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: Tokens.padding.small
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                IconTextButton {
                    Layout.fillWidth: true
                    inactiveColour: Colours.palette.m3secondaryContainer
                    inactiveOnColour: Colours.palette.m3onSecondaryContainer
                    verticalPadding: Tokens.padding.small
                    text: TimerService.running ? qsTr("Pause") : qsTr("Resume")
                    icon: TimerService.running ? "pause" : "play_arrow"
                    onClicked: {
                        if (TimerService.running)
                            TimerService.pause();
                        else
                            TimerService.resume();
                    }
                }

                IconTextButton {
                    inactiveColour: Colours.palette.m3errorContainer
                    inactiveOnColour: Colours.palette.m3onErrorContainer
                    verticalPadding: Tokens.padding.small
                    text: qsTr("Cancel")
                    icon: "close"
                    onClicked: TimerService.cancel()
                }
            }
        }
    }

    component SpinGroup: ColumnLayout {
        id: spinGroup

        property int value: 0
        property int min: 0
        property int max: 99
        property string label: ""

        signal valueModified(int v)

        spacing: 2

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: spinGroup.label
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            color: "transparent"
            radius: Tokens.rounding.small
            implicitWidth: numBox.implicitWidth
            implicitHeight: arrowIcon.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onSurface
                onClicked: {
                    const v = Math.min(spinGroup.max, spinGroup.value + 1);
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    numInput.text = String(v).padStart(2, "0");
                }
            }

            MaterialIcon {
                id: arrowIcon
                anchors.centerIn: parent
                text: "keyboard_arrow_up"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
            }
        }

        StyledRect {
            id: numBox
            Layout.alignment: Qt.AlignHCenter
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.small
            implicitWidth: numText.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: numText.implicitHeight + Tokens.padding.small * 2

            StyledText {
                id: numText
                visible: false
                text: "00"
                font.pointSize: Tokens.font.size.larger
                font.family: Tokens.font.family.mono
            }

            TextInput {
                id: numInput
                anchors.centerIn: parent
                width: numText.implicitWidth

                text: String(spinGroup.value).padStart(2, "0")
                font.pointSize: Tokens.font.size.larger
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3onSurface
                selectionColor: Colours.palette.m3primary
                selectedTextColor: Colours.palette.m3onPrimary
                horizontalAlignment: TextInput.AlignHCenter
                inputMethodHints: Qt.ImhDigitsOnly
                maximumLength: 2
                selectByMouse: true

                onTextEdited: {
                    const v = Math.min(spinGroup.max, Math.max(spinGroup.min, parseInt(text) || 0));
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                }

                function commit(): void {
                    const v = Math.min(spinGroup.max, Math.max(spinGroup.min, parseInt(text) || 0));
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    text = String(v).padStart(2, "0");
                }

                onEditingFinished: commit()
                onActiveFocusChanged: {
                    if (activeFocus)
                        selectAll();
                    else
                        commit();
                }
                Keys.onEscapePressed: {
                    text = String(spinGroup.value).padStart(2, "0");
                    focus = false;
                }
            }
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            color: "transparent"
            radius: Tokens.rounding.small
            implicitWidth: numBox.implicitWidth
            implicitHeight: arrowIcon.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onSurface
                onClicked: {
                    const v = Math.max(spinGroup.min, spinGroup.value - 1);
                    spinGroup.value = v;
                    spinGroup.valueModified(v);
                    numInput.text = String(v).padStart(2, "0");
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "keyboard_arrow_down"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.normal
            }
        }
    }
}
