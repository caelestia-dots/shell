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
    // Only read by scripts/settings-index-check.py
    property bool searchable: true
    readonly property int cappedWidth: Math.min(Tokens.sizes.nexus.maxContentWidth, width)
    readonly property alias flickable: flickable
    readonly property int stackStatus: StackView.view ? StackView.status : StackView.Active

    default property Item contentChild

    function scrollToAnchor(anchor: string): bool {
        if (!anchor || !contentChild)
            return false;
        const row = findAnchor(contentChild, anchor);
        if (!row)
            return false;
        scrollAnim.to = scrollTarget(row);
        scrollAnim.restart();
        if (row.flashHighlight !== undefined) // qmllint disable missing-property
            row.flashHighlight(); // qmllint disable missing-property
        return true;
    }

    function scrollTarget(row: Item): real {
        const pos = row.mapToItem(flickable.contentItem, 0, 0);
        const inset = flickable.height * flickable.fadeAmount + Tokens.padding.large;
        const minY = -flickable.topMargin;
        const maxY = Math.max(minY, flickable.contentHeight + flickable.bottomMargin - flickable.height);
        return Math.max(minY, Math.min(pos.y - inset, maxY));
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
        scrollRetry.settledFrames = 0;
        scrollRetry.row = null;
        scrollRetry.restart();
    }

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
    StackView.onActivated: {
        if (!scrollRetry.running)
            applySearchAnchor();
    }

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
        property int settledFrames: 0
        property Item row

        function flashIfInPlace(): bool {
            if (!row)
                row = root.findAnchor(root.contentChild, root.nState.searchAnchor);
            if (!row || row.height <= 0 || flickable.contentHeight <= 0)
                return false;
            if (Math.abs(root.scrollTarget(row) - flickable.contentY) >= 1)
                return false;
            if (row.flashHighlight !== undefined) // qmllint disable missing-property
                row.flashHighlight(); // qmllint disable missing-property
            return true;
        }

        interval: 16
        repeat: true
        onTriggered: {
            // A popped page lives until its exit transition ends, leave the anchor to the incoming copy
            if (root.stackStatus === StackView.Deactivating) {
                stop();
                return;
            }

            // Async content (e.g. ethernet details) keeps growing the layout, wait for it to hold steady
            const h = flickable.contentHeight;
            const unchanged = h === lastHeight && h > 0;
            stableFrames = unchanged && h > flickable.height ? stableFrames + 1 : 0;
            settledFrames = unchanged ? settledFrames + 1 : 0;
            lastHeight = h;

            // A page shorter than the view never counts as stable above, so flash it once settled
            if (settledFrames >= 3 && root.stackStatus === StackView.Active && flashIfInPlace()) {
                root.nState.searchAnchor = "";
                stop();
                return;
            }

            // A page still being pushed keeps waiting, one covered by another page gives up
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
