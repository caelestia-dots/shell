import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

ColumnLayout {
    spacing: Tokens.spacing.small

    StyledText {
        text: Hypr.capsLock ? Tr.tr("Capslock enabled") : Tr.tr("Capslock disabled")
    }

    StyledText {
        text: Hypr.numLock ? Tr.tr("Numlock enabled") : Tr.tr("Numlock disabled")
    }
}
