import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property var dialog
    required property FolderContents folder

    implicitHeight: inner.implicitHeight + Tokens.padding.normal * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.normal

        spacing: Tokens.spacing.small

        StyledText {
            text: qsTr("Filter:")
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Tokens.spacing.normal

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.small

            StyledText {
                anchors.fill: parent
                anchors.margins: Tokens.padding.normal

                text: `${root.dialog.filterLabel} (${root.dialog.filters.map(f => `*.${f}`).join(", ")})`
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.small

            implicitWidth: cancelText.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.normal * 2

            StateLayer {
                disabled: !root.dialog.selectionValid
                onClicked: root.dialog.accepted(root.folder.currentItem.modelData.path)
            }

            StyledText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.normal

                text: qsTr("Select")
                color: root.dialog.selectionValid ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.small

            implicitWidth: cancelText.implicitWidth + Tokens.padding.normal * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.normal * 2

            StateLayer {
                onClicked: {
                    root.dialog.rejected();
                }
            }

            StyledText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.normal

                text: qsTr("Cancel")
            }
        }
    }
}
