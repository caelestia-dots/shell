pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

StyledRect {
    id: root

    required property var dialog

    // dir: real folder under $HOME, resolved from the XDG user dirs so it
    // is always correct regardless of system language (e.g. "Descargas"
    // instead of "Downloads"). Shown as-is, so no translation needed.
    // Falls back to the English name when the dir is outside $HOME.
    readonly property var places: [
        {
            dir: "Home",
            icon: "home"
        },
        {
            dir: userDirName(StandardPaths.DownloadLocation, "Downloads"),
            icon: "file_download"
        },
        {
            dir: userDirName(StandardPaths.DesktopLocation, "Desktop"),
            icon: "desktop_windows"
        },
        {
            dir: userDirName(StandardPaths.DocumentsLocation, "Documents"),
            icon: "description"
        },
        {
            dir: userDirName(StandardPaths.MusicLocation, "Music"),
            icon: "music_note"
        },
        {
            dir: userDirName(StandardPaths.PicturesLocation, "Pictures"),
            icon: "image"
        },
        {
            dir: userDirName(StandardPaths.MoviesLocation, "Videos"),
            icon: "video_library"
        }
    ]

    // Basename of the XDG user dir for the given StandardPaths location,
    // e.g. "Descargas" instead of "Downloads" on a Spanish system.
    // Falls back to the English name when the dir is outside $HOME.
    function userDirName(location: int, fallback: string): string {
        const path = Paths.toLocalFile(StandardPaths.writableLocation(location));
        if (path.startsWith(Paths.home + "/"))
            return path.slice(Paths.home.length + 1);
        return fallback;
    }

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.medium
            text: Tr.trCtx("Files", "file dialog sidebar heading")
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        Repeater {
            model: root.places

            StyledRect {
                id: place

                required property var modelData
                readonly property bool selected: modelData.dir === root.dialog.cwd[root.dialog.cwd.length - 1]

                Layout.fillWidth: true
                implicitHeight: placeInner.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

                StateLayer {
                    color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onClicked: {
                        if (place.modelData.dir === "Home")
                            root.dialog.cwd = ["Home"];
                        else
                            root.dialog.cwd = ["Home", place.modelData.dir];
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
                        text: place.modelData.icon
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
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
                        text: place.modelData.dir
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
