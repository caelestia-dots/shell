import ".."
import qs.services
import qs.config
import QtQuick.Layouts

StyledRect {
    id: root

    required property var dialog
    required property FolderContents folder

    implicitHeight: inner.implicitHeight + Appearance.padding.normal * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Appearance.padding.normal

        spacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Filter:")
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Appearance.spacing.normal

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Appearance.rounding.small

            StyledText {
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal

                text: `${root.dialog.filterLabel} (${root.dialog.filters.map(f => `*.${f}`).join(", ")})`
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Appearance.rounding.small

            implicitWidth: cancelText.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: cancelText.implicitHeight + Appearance.padding.normal * 2

            StateLayer {
                disabled: !root.dialog.selectionValid

                function onClicked(): void {
                    root.dialog.accepted(root.folder.currentItem.filePath);
                }
            }

            StyledText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: Appearance.padding.normal

                text: qsTr("Select")
                color: root.dialog.selectionValid ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Appearance.rounding.small

            implicitWidth: cancelText.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: cancelText.implicitHeight + Appearance.padding.normal * 2

            StateLayer {
                function onClicked(): void {
                    root.dialog.rejected();
                }
            }

            StyledText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: Appearance.padding.normal

                text: qsTr("Cancel")
            }
        }
    }
}
