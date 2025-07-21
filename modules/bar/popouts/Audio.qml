import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell


Column {
    id: root

    spacing: Appearance.spacing.normal
    width: Math.max(volumeSlider.implicitWidth, pavuButton.implicitWidth)

    VerticalSlider {
        id: volumeSlider

        icon: {
            if (Audio.muted)
                return "no_sound";
            if (value >= 0.5)
                return "volume_up";
            if (value > 0)
                return "volume_down";
            return "volume_mute";
        }

        value: Audio.volume
        onMoved: Audio.setVolume(value)

        implicitWidth: Config.osd.sizes.sliderWidth
        implicitHeight: Config.osd.sizes.sliderHeight
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.1)
        visible: true
    }

    StyledRect {
        id: pavuButton
        width: parent.width
        height: 40
        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainer

        StateLayer {
            radius: parent.radius
            color: Colours.palette.m3onSurface
            function onClicked(): void {
                Quickshell.execDetached(["pavucontrol"]);
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 0
            width: parent.width - Appearance.padding.small * 2

            MaterialIcon {
                text: "settings"
                color: Colours.palette.m3onSurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
