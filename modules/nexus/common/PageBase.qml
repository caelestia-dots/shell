pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property string title
    required property NexusState nState
    property bool isSubPage
    readonly property int cappedWidth: Math.min(Tokens.sizes.nexus.maxContentWidth, width)
    readonly property alias flickable: flickable

    default property Item contentChild
    // Enables a smooth scroll animation only for search jumps, so normal
    // flicking stays instant.
    property bool animateScroll: false

    // When the settings search jumps to this page, scroll to the matching row.
    function scrollToAnchor(anchor: string): bool {
        if (!anchor || !contentChild)
            return false;
        const row = findAnchor(contentChild, anchor);
        if (!row)
            return false;
        const pos = row.mapToItem(flickable.contentItem, 0, 0);
        // Land the row below the top fade so it isn't dimmed by the edge effect,
        // clamped to the flickable's real scroll range (which includes margins).
        const inset = flickable.height * flickable.fadeAmount + Tokens.padding.large;
        const minY = -flickable.topMargin;
        const maxY = Math.max(minY, flickable.contentHeight + flickable.bottomMargin - flickable.height);
        const target = Math.max(minY, Math.min(pos.y - inset, maxY));
        root.animateScroll = true;
        flickable.contentY = target;
        Qt.callLater(() => root.animateScroll = false);
        if (row.flashHighlight !== undefined) // qmllint disable missing-property
            row.flashHighlight(); // qmllint disable missing-property
        return true;
    }

    function findAnchor(item: Item, anchor: string): Item {
        if (!item)
            return null;
        if (item.settingAnchor !== undefined && item.settingAnchor === anchor) // qmllint disable missing-property
            return item;
        const kids = item.children;
        for (let i = 0; i < kids.length; i++) {
            const found = findAnchor(kids[i], anchor);
            if (found)
                return found;
        }
        return null;
    }

    function applySearchAnchor(): void {
        if (!nState.searchAnchor)
            return;
        scrollRetry.tries = 0;
        scrollRetry.lastHeight = -1;
        scrollRetry.stableFrames = 0;
        scrollRetry.restart();
    }

    // Flash a row without scrolling (used when re-selecting the current setting).
    function highlightAnchor(anchor: string): void {
        const row = findAnchor(contentChild, anchor);
        if (row && row.flashHighlight !== undefined) // qmllint disable missing-property
            row.flashHighlight(); // qmllint disable missing-property
    }

    spacing: Tokens.spacing.extraLargeIncreased

    Component.onCompleted: applySearchAnchor()

    Timer {
        id: scrollRetry

        property int tries: 0
        property real lastHeight: -1
        property int stableFrames: 0

        interval: 16
        repeat: true
        onTriggered: {
            // Pages like the ethernet detail load their content asynchronously
            // (device info, IP config), so the layout keeps growing for a while.
            // Wait until contentHeight has held steady for a few frames (or we've
            // waited long enough) before scrolling, so the target doesn't drift.
            const h = flickable.contentHeight;
            if (h === lastHeight && h > flickable.height)
                stableFrames++;
            else
                stableFrames = 0;
            lastHeight = h;

            const ready = stableFrames >= 3 || tries >= 30;
            if (ready) {
                if (root.scrollToAnchor(root.nState.searchAnchor))
                    root.nState.searchAnchor = "";
                stop();
            }
            tries++;
        }
    }

    Connections {
        function onSearchAnchorChanged(): void {
            root.applySearchAnchor();
        }

        function onHighlightSetting(anchor: string): void {
            root.highlightAnchor(anchor);
        }

        target: root.nState
    }

    MouseArea { // Prevent clicks from reaching flickable
        z: 1
        implicitWidth: header.implicitWidth
        implicitHeight: header.implicitHeight - Layout.bottomMargin
        Layout.bottomMargin: -flickable.topMargin // Extra height to block clicks on flickable top margin
        onClicked: focus = true

        RowLayout {
            id: header

            spacing: Tokens.spacing.largeIncreased

            Loader {
                visible: active
                active: root.isSubPage
                asynchronous: true
                sourceComponent: IconButton {
                    icon: "arrow_back"
                    font: Tokens.font.icon.medium
                    type: IconButton.Tonal
                    isRound: true
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    onClicked: root.nState.closeSubPage()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font: Tokens.font.title.large
                elide: Text.ElideRight
            }
        }
    }

    VerticalFadeFlickable {
        id: flickable

        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.topMargin: -topMargin
        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.extraLarge

        contentHeight: root.contentChild?.implicitHeight ?? 0
        contentItem.children: [root.contentChild]

        rebound: Transition {
            Anim {
                properties: "x,y"
                type: Anim.DefaultEffects
            }
        }

        Behavior on contentY {
            enabled: root.animateScroll

            Anim {
                type: Anim.DefaultSpatial
            }
        }

        TapHandler {
            onTapped: flickable.focus = true
        }
    }
}
