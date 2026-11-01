pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus

// Shown for Nexus pages that aren't built yet
Item {
    property NexusState nState // To avoid the warning from non-existent property

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.padding.extraSmall

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: "handyman"
            color: Colours.palette.m3outlineVariant
            fontStyle: Tokens.font.icon.extraLarge
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            // qmllint disable unqualified
            text: Tr.tr("Page under construction")
            // qmllint enable unqualified
            color: Colours.palette.m3outlineVariant
            font: Tokens.font.title.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            // qmllint disable unqualified
            text: Tr.tr("This page will be available in a future update.")
            // qmllint enable unqualified
            color: Colours.palette.m3outlineVariant
            font: Tokens.font.body.large
        }
    }
}
