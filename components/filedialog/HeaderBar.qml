pragma ComponentBehavior: Bound

import ".."
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services

StyledRect {
    id: root

    required property var dialog

    implicitWidth: inner.implicitWidth + Tokens.padding.normal * 2
    implicitHeight: inner.implicitHeight + Tokens.padding.normal * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.normal
        spacing: Tokens.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: upIcon.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                function onClicked(): void {
                    root.dialog.cwd.pop();
                }

                radius: Tokens.rounding.small
                disabled: root.dialog.cwd.length === 1
            }

            MaterialIcon {
                id: upIcon

                anchors.centerIn: parent
                text: "drive_folder_upload"
                color: root.dialog.cwd.length === 1 ? Colours.palette.m3outline : Colours.palette.m3onSurface
                grade: 200
            }
        }

        StyledRect {
            Layout.fillWidth: true

            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh

            implicitHeight: pathComponents.implicitHeight + pathComponents.anchors.margins * 2

            RowLayout {
                id: pathComponents

                anchors.fill: parent
                anchors.margins: Tokens.padding.small / 2
                anchors.leftMargin: 0

                spacing: Tokens.spacing.small

                Repeater {
                    model: root.dialog.cwd

                    RowLayout {
                        id: folder

                        required property string modelData
                        required property int index

                        spacing: 0

                        Loader {
                            asynchronous: true
                            Layout.rightMargin: Tokens.spacing.small
                            active: folder.index > 0
                            sourceComponent: StyledText {
                                text: "/"
                                color: Colours.palette.m3onSurfaceVariant
                                font.bold: true
                            }
                        }

                        Item {
                            implicitWidth: homeIcon.implicitWidth + (homeIcon.active ? Tokens.padding.small : 0) + folderName.implicitWidth + Tokens.padding.normal * 2
                            implicitHeight: folderName.implicitHeight + Tokens.padding.small * 2

                            Loader {
                                asynchronous: true
                                anchors.fill: parent
                                active: folder.index < root.dialog.cwd.length - 1
                                sourceComponent: StateLayer {
                                    function onClicked(): void {
                                        root.dialog.cwd = root.dialog.cwd.slice(0, folder.index + 1);
                                    }

                                    radius: Tokens.rounding.small
                                }
                            }

                            Loader {
                                id: homeIcon

                                asynchronous: true

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.normal

                                active: folder.index === 0 && folder.modelData === "Home"
                                sourceComponent: MaterialIcon {
                                    text: "home"
                                    color: root.dialog.cwd.length === 1 ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                    fill: 1
                                }
                            }

                            StyledText {
                                id: folderName

                                anchors.left: homeIcon.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: homeIcon.active ? Tokens.padding.small : 0

                                text: folder.modelData
                                color: folder.index < root.dialog.cwd.length - 1 ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                                font.bold: true
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
