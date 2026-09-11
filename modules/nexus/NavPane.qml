import "navpane"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    spacing: Tokens.spacing.large

    SearchBar {
        id: searchField

        // The list below is pulled up under this by a negative margin so its
        // fade starts behind the field. That overlap is interactive - a
        // scrolled result sitting in it would swallow clicks meant for the
        // field - so keep the field on top.
        z: 1

        Layout.fillWidth: true

        placeholderText: Tr.tr("Search settings")
        font: Tokens.font.body.large

        bg.color: Colours.tPalette.m3surfaceContainerLowest
        bg.border.color: Colours.palette.m3outlineVariant
        searchIcon.fontStyle: Tokens.font.icon.medium
        searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
        clearIcon.font: Tokens.font.icon.medium
        clearIcon.padding: Tokens.padding.extraSmall

        onAccepted: locations.openSelection()

        // The results are navigated from here, so the keys only work while the
        // field has focus. Ctrl+J/K too, like the launcher's vim keybinds.
        Keys.onUpPressed: locations.moveSelection(-1)
        Keys.onDownPressed: locations.moveSelection(1)
        Keys.onPressed: event => {
            if (!(event.modifiers & Qt.ControlModifier) || !root.nState.searchOpen)
                return;

            if (event.key === Qt.Key_J) {
                locations.moveSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                locations.moveSelection(-1);
                event.accepted = true;
            }
        }

        Behavior on bg.border.color {
            CAnim {}
        }

        Binding {
            target: root.nState
            property: "searchOpen"
            value: searchField.text.length > 0
        }

        Binding {
            target: root.nState
            property: "searchText"
            value: searchField.text
        }
    }

    SearchFilters {
        // Above the list's fade overlap, like the field
        z: 1

        Layout.fillWidth: true
        visible: locations.allGroups.length > 1

        groups: locations.allGroups
        current: locations.activeFilter

        onSelected: pageIdx => locations.pageFilter = pageIdx
    }

    NavLocations {
        id: locations

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        nState: root.nState
        keyboardActive: searchField.activeFocus
    }

    StyledText {
        z: 1

        Layout.fillWidth: true
        visible: locations.resultCount > 0

        text: {
            const parts = [Tr.trN("%n result found", "%n results found", locations.resultCount)];
            // The key hints only apply while the field has focus
            if (searchField.activeFocus) {
                // TRANSLATORS: ↑↓ are the up and down arrow keys
                parts.push(Tr.tr("Use ↑↓ to navigate"), Tr.tr("Press Enter to select"));
            }
            return parts.join("  ·  ");
        }
        color: Colours.palette.m3outline
        font: Tokens.font.label.small
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
