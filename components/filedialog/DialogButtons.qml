import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.services

StyledRect {
    id: root

    required property var dialog
    required property FolderContents folder

    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Hallownest.shell

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.trCtx("Filter:", "file filter")
            color: Hallownest.subtext
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Tokens.spacing.medium

            color: Hallownest.card
            border.width: 1
            border.color: Hallownest.border
            radius: 9

            StyledText {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                color: Hallownest.text

                text: {
                    const filters = root.dialog.filters.map(f => `*.${f}`).join(Tr.trCtx(", ", "file filter separator"));
                    // TRANSLATORS: %1 = filter label, %2 = file patterns
                    return Tr.trCtx("%1 (%2)", "file filter label and patterns").arg(root.dialog.filterLabel).arg(filters);
                }
            }
        }

        HkButton {
            text: Tr.trCtx("Select", "button")
            filled: true
            disabled: !root.dialog.selectionValid
            onClicked: root.dialog.accepted(root.folder.currentItem.modelData.path)
        }

        HkButton {
            text: Tr.trCtx("Cancel", "button")
            onClicked: root.dialog.rejected()
        }
    }
}
