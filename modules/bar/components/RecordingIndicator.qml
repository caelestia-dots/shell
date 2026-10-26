pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services

MouseArea {
    id: root

    required property var screenState

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: col.implicitHeight + Tokens.padding.medium * 2

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            Recorder.stop();
            return;
        }
        // Left click: jump to utilities so controls stay reachable across workspaces
        root.screenState.utilities = true;
    }
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: root.containsMouse ? Colours.palette.m3error : Colours.palette.m3errorContainer

        Behavior on color {
            CAnim {}
        }
    }

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "screen_record"
            color: root.containsMouse ? Colours.palette.m3onError : Colours.palette.m3onErrorContainer
            fill: 1

            SequentialAnimation on opacity {
                running: !Recorder.paused
                loops: Animation.Infinite
                Anim {
                    from: 1
                    to: 0.35
                    duration: Tokens.anim.durations.large
                }
                Anim {
                    from: 0.35
                    to: 1
                    duration: Tokens.anim.durations.large
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: Recorder.paused ? Tr.trCtx("PAUSE", "recording status") : Tr.trCtx("REC", "recording status")
            color: root.containsMouse ? Colours.palette.m3onError : Colours.palette.m3onErrorContainer
            font: Tokens.font.label.builders.small.scale(0.85).build()
        }
    }

    // Keep Recorder polled while this indicator is alive
    Ref {
        service: Recorder
    }
}
