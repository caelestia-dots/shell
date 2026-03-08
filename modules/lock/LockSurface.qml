pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running

    readonly property string screenName: root.screen?.name ?? ""
    readonly property bool vertical: Config.lock.verticalScreens.includes(screenName)
    readonly property real contentRatio: vertical ? Config.lock.sizes.ratioVertical : Config.lock.sizes.ratio
    readonly property bool disabled: (Config.lock.excludedScreens ?? []).includes(screenName)

    color: "transparent"

    Connections {
        target: root.lock
        function onUnlock(): void {
            if (root.disabled)
                root.lock.locked = false;
            else
                unlockAnim.start();
        }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            Anim {
                target: lockContent
                properties: "implicitWidth,implicitHeight"
                to: lockContent.size
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: lockBg
                property: "radius"
                to: lockContent.radius
            }
            Anim {
                target: lockContent.contentItem
                property: "scale"
                to: 0
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: lockContent.contentItem
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.large
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.large
            }
            SequentialAnimation {
                PauseAnimation { duration: Appearance.anim.durations.small }
                Anim {
                    target: lockContent
                    property: "opacity"
                    to: 0
                }
            }
        }

        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    Anim {
        id: bgInitAnim
        running: true
        target: background
        property: "opacity"
        to: 1
        duration: Appearance.anim.durations.large
    }

    SequentialAnimation {
        id: uiInitAnim
        running: !root.disabled

        ParallelAnimation {
            Anim {
                target: lockContent
                property: "scale"
                to: 1
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
            Anim {
                target: lockContent
                property: "rotation"
                to: 360
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
        }

        ParallelAnimation {
            Anim {
                target: lockIcon
                property: "rotation"
                to: 360
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 0
            }
            Anim {
                target: lockContent.contentItem
                property: "opacity"
                to: 1
            }
            Anim {
                target: lockContent.contentItem
                property: "scale"
                to: 1
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: lockBg
                property: "radius"
                to: Appearance.rounding.large * 1.5
            }
            Anim {
                target: lockContent
                property: "implicitWidth"
                to: root.screen.height * Config.lock.sizes.heightMult * root.contentRatio
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: lockContent
                property: "implicitHeight"
                to: root.screen.height * Config.lock.sizes.heightMult
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    ScreencopyView {
        id: background
        anchors.fill: parent
        captureSource: root.screen
        opacity: 0

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }
    }

    Item {
        id: lockContent

        readonly property int size: lockIcon.implicitHeight + Appearance.padding.large * 4
        readonly property int radius: size / 4 * Appearance.rounding.scale
        readonly property Item contentItem: root.vertical ? contentVertical : contentHorizontal

        anchors.centerIn: parent
        implicitWidth: size
        implicitHeight: size

        rotation: 180
        visible: !root.disabled
        scale: 0

        StyledRect {
            id: lockBg
            anchors.fill: parent
            color: Colours.palette.m3surface
            radius: parent.radius
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }
        }

        MaterialIcon {
            id: lockIcon
            anchors.centerIn: parent
            text: "lock"
            font.pointSize: Appearance.font.size.extraLarge * 4
            font.bold: true
            rotation: 180
        }

        Content {
            id: contentHorizontal
            anchors.centerIn: parent
            width: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult * root.contentRatio - Appearance.padding.large * 2
            height: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult - Appearance.padding.large * 2
            lock: root
            visible: !root.vertical
            opacity: 0
            scale: 0
        }

        ContentVertical {
            id: contentVertical
            anchors.centerIn: parent
            width: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult * root.contentRatio - Appearance.padding.large * 2
            height: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult - Appearance.padding.large * 2
            lock: root
            visible: root.vertical
            opacity: 0
            scale: 0
        }
    }
}
