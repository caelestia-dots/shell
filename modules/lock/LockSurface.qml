pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Multimedia
import Caelestia.State
import qs.components
import qs.components.hallownest
import qs.services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running
    property real filigreeDrawn

    signal gameKey(key: int, pressed: bool, isRepeat: bool)

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    color: "transparent"

    Connections {
        function onUnlock(): void {
            unlockAnim.start();
        }

        target: root.lock
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "filigreeDrawn"
                to: 0
                duration: 280
                easing.type: Easing.InQuad
            }
            // Let the Knight get up before the bench fades
            SequentialAnimation {
                PauseAnimation {
                    duration: 520
                }
                NumberAnimation {
                    target: bench
                    property: "opacity"
                    to: 0
                    duration: 280
                }
            }
            Anim {
                target: lockContent
                property: "scale"
                to: 0.95
                type: Anim.FastSpatial
            }
            Anim {
                target: lockContent
                property: "opacity"
                to: 0
                type: Anim.SlowEffects
            }
            Anim {
                target: content
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
        }
        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    ParallelAnimation {
        id: initAnim

        running: true

        Anim {
            target: background
            property: "opacity"
            to: 1
            type: Anim.StandardLarge
        }
        Anim {
            target: lockContent
            property: "scale"
            to: 1
            type: Anim.DefaultSpatial
        }
        Anim {
            target: lockContent
            property: "opacity"
            to: 1
            type: Anim.SlowEffects
        }
        SequentialAnimation {
            PauseAnimation {
                duration: 120
            }
            ParallelAnimation {
                Anim {
                    target: content
                    property: "opacity"
                    to: 1
                    type: Anim.DefaultEffects
                }
                NumberAnimation {
                    target: root
                    property: "filigreeDrawn"
                    from: 0
                    to: 1
                    duration: 720
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    Item {
        id: background

        anchors.fill: parent
        opacity: 0

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }

        Loader {
            anchors.fill: parent
            sourceComponent: Config.lock.useWallpaper ? wallpaperBackground : screencopyBackground
        }
    }

    BenchRest {
        id: benchRest

        anchors.fill: parent
        visible: NotchSettings.values.animBench
        progress: 1
        rays: 1
        opacity: root.unlocking ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        SequentialAnimation {
            running: true

            NumberAnimation {
                target: benchRest
                property: "flash"
                to: 1
                duration: 250
                easing.type: Easing.OutQuad
            }
            ParallelAnimation {
                NumberAnimation {
                    target: benchRest
                    property: "flash"
                    to: 0
                    duration: 900
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: benchRest
                    property: "progress"
                    to: 0
                    duration: 1400
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: benchRest
                    property: "rays"
                    to: 0.5
                    duration: 1400
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    Bench {
        id: bench

        visible: NotchSettings.values.animBench
        canvasScale: root.height * 0.135 / 180
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - 8 - 200 * canvasScale
    }

    HoverHandler {
        onPointChanged: bench.follow(point.position.x - bench.x, point.position.y - bench.y)
    }

    Connections {
        function onBufferChanged(): void {
            if (root.pam.buffer)
                bench.look();
        }

        function onFlashMsg(): void {
            bench.refuse();
        }

        target: root.pam
    }

    Component {
        id: screencopyBackground

        ScreencopyView {
            captureSource: root.screen
        }
    }

    Component {
        id: wallpaperBackground

        Visual {
            source: Wallpapers.current
            playing: PersistentState.wallpaperPlaying
        }
    }

    Item {
        id: lockContent

        anchors.centerIn: parent
        implicitWidth: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult * Tokens.sizes.lock.ratio
        implicitHeight: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult

        visible: Config.lock.enabled
        scale: 0.94
        opacity: 0

        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: Hallownest.shell
            border.width: 1
            border.color: Hallownest.border
            radius: 22
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha("black", Hallownest.light ? 0.3 : 0.7)
            }

            HkGrain {
                anchors.fill: parent
                anchors.margins: 1
                radius: lockBg.radius - 1
            }

            Filigree {
                anchors.fill: parent
                radius: lockBg.radius
                inset: 8
                drawn: root.filigreeDrawn
                opacity: 0.24
            }
        }

        Content {
            id: content

            anchors.centerIn: parent
            width: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult * Tokens.sizes.lock.ratio - Tokens.padding.extraLargeIncreased
            height: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult - Tokens.padding.extraLargeIncreased

            lock: root
            opacity: 0
        }
    }
}
