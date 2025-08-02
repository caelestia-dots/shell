import qs.widgets
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    required property Brightness.Monitor monitor

    padding: Appearance.padding.large

    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left

    spacing: Appearance.spacing.normal

    CustomMouseArea {
        implicitWidth: Config.osd.sizes.sliderWidth
        implicitHeight: Config.osd.sizes.sliderHeight

        onWheel: event => {
            if (event.angleDelta.y > 0)
                Audio.setVolume(Audio.volume + 0.1);
            else if (event.angleDelta.y < 0)
                Audio.setVolume(Audio.volume - 0.1);
        }

        VerticalSlider {
            anchors.fill: parent

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
        }
    }

    CustomMouseArea {
        implicitWidth: Config.osd.sizes.sliderWidth
        implicitHeight: Config.osd.sizes.sliderHeight

        onWheel: event => {
            const monitor = root.monitor;
            if (!monitor)
                return;
            if (event.angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + 0.1);
            else if (event.angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - 0.1);
        }

        VerticalSlider {
            anchors.fill: parent

            icon: `brightness_${(Math.round(value * 6) + 1)}`
            value: root.monitor?.brightness ?? 0
            onMoved: root.monitor?.setBrightness(value)
        }
    }
}
