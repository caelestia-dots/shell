import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.components.effects

StyledRect {
    id: root

    required property Toast modelData

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight + Tokens.padding.large

    radius: Tokens.rounding.large
    color: {
        if (root.modelData.type === Toast.Success)
            return Colours.palette.successContainer;
        if (root.modelData.type === Toast.Warning)
            return Colours.palette.secondary;
        if (root.modelData.type === Toast.Error)
            return Colours.palette.errorContainer;
        return Colours.palette.surface;
    }

    border.width: 1
    border.color: {
        let colour = Colours.palette.outlineVariant;
        if (root.modelData.type === Toast.Success)
            colour = Colours.palette.success;
        if (root.modelData.type === Toast.Warning)
            colour = Colours.palette.secondaryContainer;
        if (root.modelData.type === Toast.Error)
            colour = Colours.palette.error;
        return Qt.alpha(colour, 0.3);
    }

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 3
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        StyledRect {
            radius: Tokens.rounding.large
            color: {
                if (root.modelData.type === Toast.Success)
                    return Colours.palette.success;
                if (root.modelData.type === Toast.Warning)
                    return Colours.palette.secondaryContainer;
                if (root.modelData.type === Toast.Error)
                    return Colours.palette.error;
                return Colours.palette.surfaceContainerHigh;
            }

            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.large

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.modelData.icon
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.onSuccess;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.onSecondaryContainer;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.onError;
                    return Colours.palette.onSurfaceVariant;
                }
                fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title

                Layout.fillWidth: true
                text: Tr.trMarked(root.modelData.title)
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.onErrorContainer;
                    return Colours.palette.onSurface;
                }
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Tr.trMarked(root.modelData.message)
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.onErrorContainer;
                    return Colours.palette.onSurface;
                }
                opacity: 0.8
                elide: Text.ElideRight
            }
        }
    }

    Behavior on border.color {
        CAnim {}
    }
}
