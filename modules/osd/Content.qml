pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property Brightness.Monitor monitor
    required property ScreenState screenState

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted
    required property real brightness

    property bool isHorizontal: false
    property string edge: "right"

    readonly property real centerOffsetX: {
        if (isHorizontal)
            return 0;
        const offset = CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large) / 2;
        return edge === "left" ? -offset : offset;
    }

    readonly property real centerOffsetY: {
        if (!isHorizontal)
            return 0;
        const offset = CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large) / 2;
        return edge === "top" ? -offset : offset;
    }

    implicitWidth: layout.implicitWidth + Tokens.padding.large * (isHorizontal ? 2 : 1) + Math.abs(centerOffsetX) * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * (isHorizontal ? 1 : 2) + Math.abs(centerOffsetY) * 2

    Grid {
        id: layout

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.centerOffsetX
        anchors.verticalCenterOffset: root.centerOffsetY

        spacing: Tokens.spacing.medium
        columns: root.isHorizontal ? 3 : 1
        rows: root.isHorizontal ? 1 : 3

        CustomMouseArea {
            function onWheel(event: WheelEvent) {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            width: root.isHorizontal ? Tokens.sizes.osd.sliderHeight : Tokens.sizes.osd.sliderWidth
            height: root.isHorizontal ? Tokens.sizes.osd.sliderWidth : Tokens.sizes.osd.sliderHeight

            FilledSlider {
                anchors.fill: parent
                isHorizontal: root.isHorizontal
                icon: Icons.getVolumeIcon(value, root.muted)
                value: root.volume
                to: GlobalConfig.services.maxVolume
                onMoved: Audio.setVolume(value)
            }
        }

        WrappedLoader {
            shouldBeActive: Config.osd.enableMicrophone && (!Config.osd.enableBrightness || !root.screenState.session)

            sourceComponent: CustomMouseArea {
                function onWheel(event: WheelEvent) {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume();
                }

                width: root.isHorizontal ? Tokens.sizes.osd.sliderHeight : Tokens.sizes.osd.sliderWidth
                height: root.isHorizontal ? Tokens.sizes.osd.sliderWidth : Tokens.sizes.osd.sliderHeight

                FilledSlider {
                    anchors.fill: parent
                    isHorizontal: root.isHorizontal
                    icon: Icons.getMicVolumeIcon(value, root.sourceMuted)
                    value: root.sourceVolume
                    to: GlobalConfig.services.maxVolume
                    onMoved: Audio.setSourceVolume(value)
                }
            }
        }

        WrappedLoader {
            shouldBeActive: Config.osd.enableBrightness

            sourceComponent: CustomMouseArea {
                function onWheel(event: WheelEvent) {
                    const monitor = root.monitor;
                    if (!monitor)
                        return;
                    if (event.angleDelta.y > 0)
                        monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
                    else if (event.angleDelta.y < 0)
                        monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
                }

                width: root.isHorizontal ? Tokens.sizes.osd.sliderHeight : Tokens.sizes.osd.sliderWidth
                height: root.isHorizontal ? Tokens.sizes.osd.sliderWidth : Tokens.sizes.osd.sliderHeight

                FilledSlider {
                    anchors.fill: parent
                    isHorizontal: root.isHorizontal
                    icon: `brightness_${(Math.round(value * 6) + 1)}`
                    value: root.brightness
                    onMoved: root.monitor?.setBrightness(value)
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property bool shouldBeActive

        asynchronous: true

        property real targetW: root.isHorizontal ? Tokens.sizes.osd.sliderHeight : Tokens.sizes.osd.sliderWidth
        property real targetH: root.isHorizontal ? Tokens.sizes.osd.sliderWidth : Tokens.sizes.osd.sliderHeight

        width: shouldBeActive ? targetW : 0
        height: shouldBeActive ? targetH : 0

        opacity: shouldBeActive ? 1 : 0
        active: opacity > 0
        visible: active

        Behavior on width {
            Anim {
                type: Anim.Emphasized
            }
        }

        Behavior on height {
            Anim {
                type: Anim.Emphasized
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
