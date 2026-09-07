import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

ColumnLayout {
    spacing: Tokens.spacing.small

    StyledText {
        text: Hypr.capsLock ? Tr.tr("Capslock: Enabled") : Tr.tr("Capslock: Disabled")
    }

    StyledText {
        text: Hypr.numLock ? Tr.tr("Numlock: Enabled") : Tr.tr("Numlock: Disabled")
    }
}
