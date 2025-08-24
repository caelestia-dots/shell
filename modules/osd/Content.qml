import qs.components.controls
import qs.services
import qs.config
import qs.utils
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
        // Add scroll accumulation properties
        property int scrollAccumulatedY: 0
        property int scrollThreshold: 250  // Adjust this to make it more/less sensitive

        onWheel: event => {
            // Update accumulated scroll
            if (Math.sign(event.angleDelta.y) !== Math.sign(scrollAccumulatedY))
                scrollAccumulatedY = 0;
            scrollAccumulatedY += event.angleDelta.y;

            // Trigger handler and reset if above threshold
            if (Math.abs(scrollAccumulatedY) >= scrollThreshold) {
                if (scrollAccumulatedY > 0)
                    Audio.incrementVolume();
                else if (scrollAccumulatedY < 0)
                    Audio.decrementVolume();
                scrollAccumulatedY = 0;
            }
        }
        FilledSlider {
            anchors.fill: parent

            icon: Icons.getVolumeIcon(value, Audio.muted)
            value: Audio.volume
            onMoved: Audio.setVolume(value)
        }
    }

    CustomMouseArea {
        implicitWidth: Config.osd.sizes.sliderWidth
        implicitHeight: Config.osd.sizes.sliderHeight

        // Add scroll accumulation properties
        property int scrollAccumulatedY: 0
        property int scrollThreshold: 250  // Adjust this to make it more/less sensitive
        onWheel: event => {
            const monitor = root.monitor;

            if (!monitor)
                return;
            if (Math.sign(event.angleDelta.y) !== Math.sign(scrollAccumulatedY))
                scrollAccumulatedY = 0;

            scrollAccumulatedY += event.angleDelta.y;
            if (Math.abs(scrollAccumulatedY) >= scrollThreshold) {
                if (scrollAccumulatedY > 0)
                    monitor.setBrightness(monitor.brightness + 0.1);
                else if (scrollAccumulatedY < 0)
                    monitor.setBrightness(monitor.brightness - 0.1);
                scrollAccumulatedY = 0;
            }
        }
        FilledSlider {
            anchors.fill: parent

            icon: `brightness_${(Math.round(value * 6) + 1)}`
            value: root.monitor?.brightness ?? 0
            onMoved: root.monitor?.setBrightness(value)
        }
    }
}
