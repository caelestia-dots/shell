import qs.components
import qs.components.effects
import qs.services
import qs.config
import Caelestia
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property Toast modelData

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight + Appearance.padding.smaller * 2

    radius: Appearance.rounding.normal
    color: {
        if (root.modelData.type === Toast.Success)
            return Colours.palette.m3successContainer;
        if (root.modelData.type === Toast.Warning)
            return Colours.palette.m3secondary;
        if (root.modelData.type === Toast.Error)
            return Colours.palette.m3errorContainer;
        return Colours.palette.m3surface;
    }

    border.width: 1
    border.color: {
        let colour = Colours.palette.m3outlineVariant;
        if (root.modelData.type === Toast.Success)
            colour = Colours.palette.m3success;
        if (root.modelData.type === Toast.Warning)
            colour = Colours.palette.m3secondaryContainer;
        if (root.modelData.type === Toast.Error)
            colour = Colours.palette.m3error;
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
        anchors.margins: Appearance.padding.smaller
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        StyledRect {
            radius: Appearance.rounding.normal
            color: {
                if (root.modelData.type === Toast.Success)
                    return Colours.palette.m3success;
                if (root.modelData.type === Toast.Warning)
                    return Colours.palette.m3secondaryContainer;
                if (root.modelData.type === Toast.Error)
                    return Colours.palette.m3error;
                return Colours.palette.m3surfaceContainerHigh;
            }

            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Appearance.padding.smaller * 2

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.modelData.icon
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccess;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondaryContainer;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onError;
                    return Colours.palette.m3onSurfaceVariant;
                }
                font.pointSize: Math.round(Appearance.font.size.large * 1.2)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title

                Layout.fillWidth: true
                text: root.modelData.title
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
                }
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: root.modelData.message
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
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
