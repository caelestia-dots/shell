import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.components.annotation

RowLayout {
    id: root

    required property RegionState rState

    spacing: Tokens.spacing.medium

    MaterialIcon {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Tokens.padding.medium
        text: "screenshot_region"
        color: Colours.palette.onSecondaryContainer
        fontStyle: Tokens.font.icon.medium
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: Tr.tr("Drag to select a region")
        color: Colours.palette.onSecondaryContainer
        font: Tokens.font.body.medium
    }

    ButtonRow {
        spacing: Tokens.spacing.extraSmall

        ToolbarButton {
            isToggle: true
            checked: root.rState.showCrosshair
            icon: "my_location"
            onClicked: root.rState.showCrosshair = !root.rState.showCrosshair
        }

        ToolbarButton {
            isToggle: true
            checked: root.rState.selectClients
            icon: "select_window_2"
            onClicked: root.rState.selectClients = !root.rState.selectClients
        }

        ToolbarButton {
            icon: "close"
            onClicked: root.rState.cancelled()
        }
    }
}
