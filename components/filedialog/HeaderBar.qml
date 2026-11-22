pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property var dialog

    implicitWidth: inner.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Hallownest.shell

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: upIcon.implicitHeight + Tokens.padding.small

            StateLayer {
                radius: 8
                disabled: root.dialog.cwd.length === 1
                onClicked: root.dialog.cwd.pop()
            }

            MaterialIcon {
                id: upIcon

                anchors.centerIn: parent
                text: "drive_folder_upload"
                color: root.dialog.cwd.length === 1 ? Hallownest.faint : Hallownest.soul
                grade: 200
            }
        }

        StyledRect {
            Layout.fillWidth: true

            radius: 10
            color: Hallownest.card
            border.width: 1
            border.color: Hallownest.border

            implicitHeight: pathComponents.implicitHeight + pathComponents.anchors.margins * 2

            RowLayout {
                id: pathComponents

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall / 2
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
                                color: Hallownest.faint
                                font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                            }
                        }

                        Item {
                            implicitWidth: homeIcon.implicitWidth + (homeIcon.active ? Tokens.padding.extraSmall : 0) + folderName.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: folderName.implicitHeight + Tokens.padding.small

                            Loader {
                                asynchronous: true
                                anchors.fill: parent
                                active: folder.index < root.dialog.cwd.length - 1
                                sourceComponent: StateLayer {
                                    onClicked: {
                                        root.dialog.cwd = root.dialog.cwd.slice(0, folder.index + 1);
                                    }

                                    radius: 8
                                }
                            }

                            Loader {
                                id: homeIcon

                                asynchronous: true

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.medium

                                active: folder.index === 0 && folder.modelData === "Home"
                                sourceComponent: MaterialIcon {
                                    text: "home"
                                    color: root.dialog.cwd.length === 1 ? Hallownest.soul : Hallownest.subtext
                                    fill: 1
                                }
                            }

                            StyledText {
                                id: folderName

                                anchors.left: homeIcon.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: homeIcon.active ? Tokens.padding.extraSmall : 0

                                text: folder.modelData
                                color: folder.index < root.dialog.cwd.length - 1 ? Hallownest.subtext : Hallownest.soul
                                font: Tokens.font.body.builders.small.weight(Font.Bold).build()
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
