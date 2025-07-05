pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    property bool thisLocked
    readonly property bool locked: thisLocked && !lock.unlocked

    function unlock(): void {
        lock.unlocked = true;
        animDelay.start();
    }

    Component.onCompleted: thisLocked = true

    color: "transparent"

    Timer {
        id: animDelay

        interval: Appearance.anim.durations.large
        onTriggered: root.lock.locked = false
    }

    Connections {
        target: root.lock

        function onUnlockedChanged(): void {
            background.opacity = 0;
        }
    }

    ScreencopyView {
        id: background

        anchors.fill: parent
        captureSource: root.screen

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: root.locked ? 1 : 0
            blurMax: 64
            blurMultiplier: 1

            Behavior on blur {
                Anim {}
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Backgrounds {
        id: backgrounds

        locked: root.locked
        weatherWidth: weather.implicitWidth
        buttonsWidth: buttons.item?.nonAnimWidth ?? 0
        buttonsHeight: buttons.item?.nonAnimHeight ?? 0
        statusWidth: status.item?.nonAnimWidth ?? 0
        statusHeight: status.item?.nonAnimHeight ?? 0
        isNormal: root.screen.width > Config.lock.sizes.smallScreenWidth
        isLarge: root.screen.width > Config.lock.sizes.largeScreenWidth

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
        }
    }

    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: -backgrounds.clockBottom
    }

    Input {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: -backgrounds.inputTop

        lock: root
    }

    WeatherInfo {
        id: weather

        anchors.top: parent.bottom
        anchors.right: parent.left
        anchors.topMargin: -backgrounds.weatherTop
        anchors.rightMargin: -backgrounds.weatherRight
    }

    Loader {
        id: media

        active: root.screen.width > Config.lock.sizes.smallScreenWidth
        asynchronous: true

        state: root.screen.width > Config.lock.sizes.largeScreenWidth ? "tl" : "br"
        states: [
            State {
                name: "tl"

                AnchorChanges {
                    target: media
                    anchors.bottom: media.parent.top
                    anchors.right: media.parent.left
                }

                PropertyChanges {
                    media.anchors.bottomMargin: -backgrounds.mediaY
                    media.anchors.rightMargin: -backgrounds.mediaX
                }
            },
            State {
                name: "br"

                AnchorChanges {
                    target: media
                    anchors.top: media.parent.bottom
                    anchors.left: media.parent.right
                }

                PropertyChanges {
                    media.anchors.topMargin: -backgrounds.mediaY
                    media.anchors.leftMargin: -backgrounds.mediaX
                }
            }
        ]

        sourceComponent: MediaPlaying {
            isLarge: root.screen.width > Config.lock.sizes.largeScreenWidth
        }
    }

    Loader {
        id: buttons

        active: root.screen.width > Config.lock.sizes.largeScreenWidth
        asynchronous: true

        anchors.top: parent.bottom
        anchors.left: parent.right
        anchors.topMargin: -backgrounds.buttonsTop
        anchors.leftMargin: -backgrounds.buttonsLeft

        sourceComponent: Buttons {}
    }

    Loader {
        id: status

        active: root.screen.width > Config.lock.sizes.largeScreenWidth

        anchors.bottom: parent.top
        anchors.left: parent.right
        anchors.bottomMargin: -backgrounds.statusBottom
        anchors.leftMargin: -backgrounds.statusLeft

        sourceComponent: Status {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.large
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
