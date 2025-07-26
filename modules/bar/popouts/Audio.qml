import qs.widgets
import qs.services
import qs.config
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    required property var wrapper

    spacing: Appearance.spacing.normal

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

    StyledRect {
        id: pavuButton

        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.normal
        color: Colours.palette.m3surfaceContainer

        StateLayer {
            function onClicked(): void {
                root.wrapper.hasCurrent = false;
                Quickshell.execDetached(["pavucontrol"]);
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: "settings"
        }
    }
}
