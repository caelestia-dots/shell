pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen
    property bool isHorizontal: false
    property real maxWidth: screen.width * 0.4

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool onSpecial: !!monitor?.lastIpcObject.specialWorkspace?.name
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    readonly property int activeWsIdx: workspaceIndex(activeWsId)
    readonly property int shown: Math.max(1, Config.bar.workspaces.shown)
    readonly property var wsIds: {
        if (Config.bar.workspaces.showUnoccupied)
            return Array.from({
                length: shown
            }, (_, i) => i + 1);

        const allMonitors = !Config.bar.workspaces.perMonitor;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const workspaces = Hypr.workspaces.values.filter(w => w.id > 0 && (allMonitors || w.monitor === root.monitor) && (w.id === activeWsId || w.toplevels.values.some(t => !Hypr.isToplevelIgnored(t, ignoredTags))));
        const currentIdx = workspaces.findIndex(w => w.id === activeWsId);
        if (currentIdx < 0)
            return [];

        const end = CUtils.clamp(currentIdx + 1, Math.min(shown, workspaces.length), workspaces.length);
        const start = Math.max(0, end - shown);

        return workspaces.slice(start, end).map(w => w.id);
    }
    readonly property int groupOffset: Config.bar.workspaces.showUnoccupied ? Math.floor((activeWsId - 1) / shown) * shown : 0

    property real blur: onSpecial ? 1 : 0
    property real contentWidth: view.implicitWidth + Tokens.padding.extraSmall * 2

    function workspaceIndex(id: int): int {
        if (!Config.bar.workspaces.showUnoccupied)
            return wsIds.indexOf(id);
        return ((id - 1) % shown + shown) % shown;
    }

    implicitWidth: isHorizontal ? Math.max(0, Math.min(maxWidth, contentWidth)) : Tokens.sizes.bar.innerWidth
    implicitHeight: isHorizontal ? Tokens.sizes.bar.innerWidth : view.implicitHeight + Tokens.padding.extraSmall * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        WorkspaceList {
            id: view

            x: Tokens.padding.extraSmall
            y: Tokens.padding.extraSmall
            width: Math.max(0, parent.width - Tokens.padding.extraSmall * 2)
            height: Math.max(0, parent.height - Tokens.padding.extraSmall * 2)
            maxWidth: Math.max(0, root.maxWidth - Tokens.padding.extraSmall * 2)
            monitor: root.monitor
            wsIds: root.wsIds
            activeWsId: root.activeWsId
            activeIndex: root.activeWsIdx
            groupOffset: root.groupOffset
            isHorizontal: root.isHorizontal
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        anchors.fill: parent

        asynchronous: true
        active: opacity > 0
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: Item {
            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3scrim, Colours.light ? 0 : 0.2)
            }

            SpecialWorkspaces {
                x: Tokens.padding.extraSmall
                y: Tokens.padding.extraSmall
                width: Math.max(0, parent.width - Tokens.padding.extraSmall * 2)
                height: Math.max(0, parent.height - Tokens.padding.extraSmall * 2)
                monitor: root.monitor
                isHorizontal: root.isHorizontal
                scale: 0.5
                Component.onCompleted: scale = Qt.binding(() => root.onSpecial ? 1 : 0.5)

                Behavior on scale {
                    Anim {}
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Behavior on contentWidth {
        Anim {}
    }
}
