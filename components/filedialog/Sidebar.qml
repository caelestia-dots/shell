pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.components.hallownest
import qs.services

StyledRect {
    id: root

    required property var dialog

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Hallownest.shell

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        HkTitle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.extraSmall / 2
            text: Tr.trCtx("Files", "file dialog sidebar heading")
            size: 13
        }

        HkDivider {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
        }

        Repeater {
            model: ["Home", "Downloads", "Desktop", "Documents", "Music", "Pictures", "Videos"]

            StyledRect {
                id: place

                required property string modelData
                readonly property bool selected: modelData === root.dialog.cwd[root.dialog.cwd.length - 1]

                Layout.fillWidth: true
                implicitHeight: placeInner.implicitHeight + Tokens.padding.medium * 2

                radius: 10
                color: selected ? Qt.alpha(Hallownest.soul, 0.12) : "transparent"
                border.width: selected ? 1 : 0
                border.color: Qt.alpha(Hallownest.soul, 0.4)

                StateLayer {
                    color: Hallownest.soul
                    onClicked: {
                        if (place.modelData === "Home")
                            root.dialog.cwd = ["Home"];
                        else
                            root.dialog.cwd = ["Home", place.modelData];
                    }
                }

                RowLayout {
                    id: placeInner

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large

                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: {
                            const p = place.modelData;
                            if (p === "Home")
                                return "home";
                            if (p === "Downloads")
                                return "file_download";
                            if (p === "Desktop")
                                return "desktop_windows";
                            if (p === "Documents")
                                return "description";
                            if (p === "Music")
                                return "music_note";
                            if (p === "Pictures")
                                return "image";
                            if (p === "Videos")
                                return "video_library";
                            return "folder";
                        }
                        color: place.selected ? Hallownest.soul : Hallownest.subtext
                        fontStyle: Tokens.font.icon.medium
                        fill: place.selected ? 1 : 0

                        Behavior on fill {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: place.modelData
                        color: place.selected ? Hallownest.soul : Hallownest.text
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
