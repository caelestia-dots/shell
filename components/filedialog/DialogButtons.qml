import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components

StyledRect {
    id: root

    required property var dialog
    required property FolderContents folder

    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.small

        StyledText {
            text: Tr.trCtx("Filter:", "file filter")
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Tokens.spacing.medium

            color: Colours.tPalette.surfaceContainerHigh
            radius: Tokens.rounding.medium

            StyledText {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium

                text: {
                    const filters = root.dialog.filters.map(f => `*.${f}`).join(Tr.trCtx(", ", "file filter separator"));
                    // TRANSLATORS: %1 = filter label, %2 = file patterns
                    return Tr.trCtx("%1 (%2)", "file filter label and patterns").arg(root.dialog.filterLabel).arg(filters);
                }
            }
        }

        StyledRect {
            color: Colours.tPalette.surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                disabled: !root.dialog.selectionValid
                onClicked: root.dialog.accepted(root.folder.currentItem.modelData.path)
            }

            StyledText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: Tr.trCtx("Select", "button")
                color: root.dialog.selectionValid ? Colours.palette.onSurface : Colours.palette.outline
            }
        }

        StyledRect {
            color: Colours.tPalette.surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                onClicked: {
                    root.dialog.rejected();
                }
            }

            StyledText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: Tr.trCtx("Cancel", "button")
            }
        }
    }
}
