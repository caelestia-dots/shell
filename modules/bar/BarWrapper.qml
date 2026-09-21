pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    required property int position

    readonly property bool horizontal: position === BarPosition.Top || position === BarPosition.Bottom

    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int clampedExtent: Math.max(Config.border.minThickness, extent)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentThickness: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentThickness : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    property bool isHovered
    property real extent: fullscreen ? 0 : Config.border.thickness

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(pos: real): void {
        (content.item as Bar)?.checkPopout(pos);
    }

    function entryAt(pos: real): string {
        return (content.item as Bar)?.entryAt(pos) ?? "";
    }

    function handleWheel(pos: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(pos, angleDelta);
    }

    clip: true
    visible: extent > Config.border.thickness
    implicitWidth: extent
    implicitHeight: extent

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.extent: root.contentThickness
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "extent"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "extent"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        x: root.horizontal ? 0 : parent.width - width
        y: root.horizontal ? (root.position === BarPosition.Bottom ? parent.height - height : 0) : 0

        width: root.horizontal ? parent.width : root.contentThickness
        height: root.horizontal ? root.contentThickness : parent.height

        active: root.shouldBeVisible

        sourceComponent: Bar {
            position: root.position
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }
}
