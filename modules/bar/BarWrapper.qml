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

    readonly property string edge: Config.bar.alignment
    readonly property bool isHorizontal: edge === "top" || edge === "bottom"
    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentHeight: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentHeight : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    property bool isHovered

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(coord: real): void {
        (content.item as Bar)?.checkPopout(coord);
    }

    function handleWheel(coord: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(coord, angleDelta);
    }

    clip: true
    visible: isHorizontal ? height > Config.border.thickness : width > Config.border.thickness

    implicitWidth: isHorizontal ? screen.width : (fullscreen ? 0 : Config.border.thickness)
    implicitHeight: isHorizontal ? (fullscreen ? 0 : Config.border.thickness) : screen.height

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            target: root
            implicitWidth: root.isHorizontal ? root.screen.width : root.contentHeight
            implicitHeight: root.isHorizontal ? root.contentHeight : root.screen.height
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"
            ParallelAnimation {
                Anim {
                    target: root
                    property: "implicitWidth"
                }
                Anim {
                    target: root
                    property: "implicitHeight"
                }
            }
        },
        Transition {
            from: "visible"
            to: ""
            ParallelAnimation {
                Anim {
                    target: root
                    property: "implicitWidth"
                    type: Anim.Emphasized
                }
                Anim {
                    target: root
                    property: "implicitHeight"
                    type: Anim.Emphasized
                }
            }
        }
    ]

    Loader {
        id: content
        anchors.fill: parent
        active: root.shouldBeVisible

        sourceComponent: Bar {
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }
}
