pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import Caelestia.Scheme
import qs.components
import qs.components.containers
import qs.components.widgets
import qs.components.widgets.notifs
import qs.services
import qs.modules.utilities as Utilities

Item {
    id: root

    required property ScreenState screenState
    required property Item osdPanel
    required property Item sessionPanel
    required property Item utilitiesPanel
    readonly property int padding: Tokens.padding.large
    readonly property int clampedPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    implicitWidth: Tokens.sizes.notifs.width
    implicitHeight: {
        if (list.count === 0)
            return 0;

        let height = list.layoutHeight;

        if (screenState.osd) {
            const h = osdPanel.y - clampedPadding;
            if (height > h)
                height = h;
        }

        if (screenState.session) {
            const h = sessionPanel.y - clampedPadding;
            if (height > h)
                height = h;
        }

        if (screenState.utilities) {
            const h = ((QsWindow.window as QsWindow)?.screen.height ?? 0) - (utilitiesPanel as Utilities.Wrapper).nonAnimHeight - Config.border.thickness * 2 - padding * 2 - Tokens.spacing.extraLarge;
            if (height > h)
                height = h;
        }

        return Math.min(((QsWindow.window as QsWindow)?.screen?.height ?? 0) + padding - clampedPadding * 2 - Config.border.thickness, height + padding + clampedPadding);
    }

    ClippingWrapperRectangle {
        anchors.fill: parent
        anchors.margins: root.padding
        anchors.topMargin: root.clampedPadding
        anchors.rightMargin: root.clampedPadding

        color: "transparent"
        radius: Tokens.rounding.large

        StyledFlickable {
            id: view

            anchors.fill: parent

            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: list.implicitHeight

            LazyListView {
                id: list

                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: contentHeight

                spacing: Tokens.spacing.medium
                readyDelay: 1
                cacheBuffer: (QsWindow.window as QsWindow)?.screen.height ?? 0
                removeDuration: Tokens.anim.durations.normal

                useCustomViewport: true
                viewport: Qt.rect(0, view.contentY, width, view.height)

                model: ScriptModel {
                    values: [...Notifs.popupGroups]
                }

                delegate: Component {
                    NotifWrapper {}
                }

                onViewportAdjustNeeded: d => {
                    if (contentYAnim.running)
                        contentYAnim.complete();
                    contentYAnim.to = Math.max(0, view.contentY + d);
                    contentYAnim.start();
                }

                Anim {
                    id: contentYAnim

                    target: view
                    property: "contentY"
                }
            }

            ExtraIndicator {
                parent: view
                anchors.top: parent.top
                extra: {
                    const count = list.count;
                    if (count === 0)
                        return 0;

                    const scrollY = view.contentY;

                    let height = 0;
                    for (let i = 0; i < count; i++) {
                        height += ((list.itemAtIndex(i) as NotifWrapper)?.nonAnimHeight ?? 0) + list.spacing;

                        if (height - list.spacing >= scrollY)
                            return i;
                    }

                    return count;
                }
            }

            ExtraIndicator {
                parent: view
                anchors.bottom: parent.bottom
                extra: {
                    const count = list.count;
                    if (count === 0)
                        return 0;

                    const scrollY = list.contentHeight - (view.contentY + view.height);

                    let height = 0;
                    for (let i = count - 1; i >= 0; i--) {
                        height += ((list.itemAtIndex(i) as NotifWrapper)?.nonAnimHeight ?? 0) + list.spacing;

                        if (height - list.spacing >= scrollY)
                            return count - i - 1;
                    }

                    return 0;
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component NotifWrapper: Item {
        id: wrapper

        required property NotifGroup modelData
        readonly property alias nonAnimHeight: card.nonAnimHeight
        property bool expanded: Config.notifs.openExpanded
        readonly property bool holding: area.containsMouse || area.pressed || card.rowPressed

        function forEachPopup(fn: var): void {
            for (const n of [...card.notifs])
                fn(n);
        }

        function holdPopups(): void {
            forEachPopup(n => n.holdPopup());
        }

        LazyListView.trackViewport: !expanded && card.nonAnimHeight < card.implicitHeight
        LazyListView.preferredHeight: LazyListView.removing ? 0 : card.nonAnimHeight
        LazyListView.visibleHeight: LazyListView.removing ? 0 : card.implicitHeight
        LazyListView.onRemovingChanged: {
            if (!wrapper.LazyListView.removing)
                return;

            slideOut.to = (area.x >= 0 ? root.implicitWidth : -root.implicitWidth) * 2;
            slideOut.start();
        }

        implicitWidth: area.implicitWidth
        implicitHeight: card.implicitHeight

        enabled: !LazyListView.removing
        z: LazyListView.removing ? 1 : 0

        onHoldingChanged: {
            if (holding)
                holdPopups();
            else
                forEachPopup(n => n.releasePopup());
        }

        Connections {
            function onNotifsChanged(): void {
                if (wrapper.holding)
                    wrapper.holdPopups();
            }

            target: wrapper.modelData
        }

        Anim {
            id: slideOut

            target: area
            property: "x"
            duration: Tokens.anim.durations.normal
            easing: Tokens.anim.emphasized
        }

        ClipRect {
            anchors.top: parent.top

            color: "transparent"
            radius: card.radius
            implicitWidth: area.implicitWidth
            implicitHeight: card.implicitHeight

            NotifSwipeArea {
                id: area

                implicitWidth: root.implicitWidth - root.padding - root.clampedPadding
                implicitHeight: card.implicitHeight
                x: wrapper.LazyListView.adding ? implicitWidth : 0

                expanded: wrapper.expanded
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                onRequestExpand: expand => wrapper.expanded = expand
                onSwiped: wrapper.forEachPopup(n => n.dismissPopup())
                onDismissed: wrapper.forEachPopup(n => n.dismiss())
                onClicked: event => {
                    if (!GlobalConfig.notifs.actionOnClick || event.button !== Qt.LeftButton || card.notifs.length !== 1)
                        return;

                    const actions = card.notifs[0].actions;
                    if (actions.length === 1)
                        actions[0].invoke();
                }

                NotifGroupCard {
                    id: card

                    group: wrapper.modelData
                    container: view
                    expanded: wrapper.expanded
                    color: card.group.urgency === NotifData.Critical ? Colours.palette.secondaryContainer : Colours.tPalette.surfaceContainer
                    onRequestExpand: expand => wrapper.expanded = expand
                    onSwiped: notif => notif.dismissPopup()
                    onLinkActivated: notif => notif.dismissPopup()
                }
            }
        }

        Behavior on y {
            enabled: wrapper.LazyListView.ready

            Anim {}
        }
    }

    component Anim: NumberAnimation {
        duration: Tokens.anim.durations.expressiveDefaultSpatial
        easing: Tokens.anim.expressiveDefaultSpatial
    }
}
