import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active
    property bool loading
    property bool warning
    property bool first
    property bool last
    default property alias trailing: trailingRow.data

    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2

    color: active ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.large : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.large : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.large : Tokens.rounding.extraSmall

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: iconLabel.implicitHeight + Tokens.padding.small * 2

            radius: Tokens.rounding.full
            color: root.active ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHighest

            MaterialIcon {
                id: iconLabel

                anchors.centerIn: parent
                animate: true
                text: root.icon
                color: root.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                fill: root.active ? 1 : 0
            }

            CircularIndicator {
                anchors.fill: parent
                bgColour: "transparent"
                strokeWidth: Tokens.padding.extraSmall / 2
                running: root.loading
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text
                animate: true
                text: root.subtitle
                color: {
                    if (root.warning)
                        return Colours.palette.m3error;
                    return root.active ? Qt.alpha(Colours.palette.m3onSecondaryContainer, 0.8) : Colours.palette.m3onSurfaceVariant;
                }
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        RowLayout {
            id: trailingRow

            spacing: Tokens.spacing.extraSmall
        }
    }
}
