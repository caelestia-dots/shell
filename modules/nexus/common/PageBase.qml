pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
    // Where this page is in its sub-page stack; a page outside one counts as shown shown
    readonly property int stackStatus: StackView.view ? StackView.status : StackView.Active

    default property Item contentChild

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
        scrollAnim.to = target;
        scrollAnim.restart();
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

    // Flash a row when re-selecting the current setting, scrolling only if it
    // has been scrolled out of view since.
    function highlightAnchor(anchor: string): void {
        const row = findAnchor(contentChild, anchor);
        if (!row)
            return;
        const pos = row.mapToItem(flickable, 0, 0);
        if (pos.y < 0 || pos.y + row.height > flickable.height)
            scrollToAnchor(anchor);
        else if (row.flashHighlight !== undefined) // qmllint disable missing-property
            row.flashHighlight(); // qmllint disable missing-property
    }

    spacing: Tokens.spacing.extraLargeIncreased

    Component.onCompleted: applySearchAnchor()
    // A page uncovered by closing the ones above it picks up a pending jump
    StackView.onActivated: {
        if (!scrollRetry.running)
            applySearchAnchor();
    }

    // Only search jumps animate, normal flicking stays direct
    Anim {
        id: scrollAnim

        target: flickable
        property: "contentY"
        type: Anim.DefaultSpatial
    }

    Timer {
        id: scrollRetry

        property int tries: 0
        property real lastHeight: -1
        property int stableFrames: 0

        interval: 16
        repeat: true
        onTriggered: {
            // A popped page lives on until its exit transition ends, so a jump
            // that reopens the same sub-page briefly has two copies of it. The
            // outgoing one must leave the anchor to the incoming one.
            if (root.stackStatus === StackView.Deactivating) {
                stop();
                return;
            }

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

            // Only the page on show takes the anchor. One still coming in keeps
            // waiting, one covered by another page gives up.
            const ready = stableFrames >= 3 || tries >= 30;
            if (ready && root.stackStatus === StackView.Active) {
                if (root.scrollToAnchor(root.nState.searchAnchor))
                    root.nState.searchAnchor = "";
                stop();
            } else if (ready && root.stackStatus === StackView.Inactive) {
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
            if (root.stackStatus === StackView.Active)
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

        TapHandler {
            onTapped: flickable.focus = true
        }
    }
}
