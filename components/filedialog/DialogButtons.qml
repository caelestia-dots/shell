import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.components.controls

StyledRect {
    id: root

    required property DialogState dState

    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    color: Colours.tPalette.surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: 0

        spacing: Tokens.spacing.small

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Tokens.spacing.small

            color: Colours.tPalette.surfaceContainerHigh
            radius: Tokens.rounding.full

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large

                text: {
                    const entry = root.dState.selectedPath;
                    if (!entry)
                        return Tr.tr("No selected file");

                    if (entry.isDir)
                        // TRANSLATORS: %1 = selected folder
                        return Tr.trCtx("\"%1\" | Folder", "selected folder label").arg(entry.name);

                    // TRANSLATORS: %1 = file name, %2 = file size, %3 = file type
                    return Tr.trCtx("\"%1\" | %2 | %3", "selected file label").arg(entry.name).arg(Units.formatBytes(entry.size)).arg(entry.mimeComment);
                }
                elide: StyledText.ElideRight
            }
        }

        TextButton {
            isRound: true
            horizontalPadding: Tokens.padding.large
            verticalPadding: Tokens.padding.medium
            disabled: !root.dState.selectionValid
            text: Tr.trCtx("Select", "button")
            onClicked: root.dState.accepted(root.dState.selectedPath.path)
        }

        TextButton {
            type: TextButton.Tonal
            isRound: true
            horizontalPadding: Tokens.padding.large
            verticalPadding: Tokens.padding.medium
            text: Tr.trCtx("Cancel", "button")
            onClicked: root.dState.rejected()
        }
    }
}
