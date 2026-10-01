pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.services

StyledRect {
    id: root

    required property var dialog

    // Basename of the XDG user dir for the given StandardPaths location,
    // e.g. "Descargas" instead of "Downloads" on a Spanish system.
    // Falls back to the English name when the dir is outside $HOME.
    function userDirName(location: int, fallback: string): string {
        const path = Paths.toLocalFile(StandardPaths.writableLocation(location));
        if (path.startsWith(Paths.home + "/"))
            return path.slice(Paths.home.length + 1);
        return fallback;
    }

    // dir: real folder under $HOME. label: static translatable string so it
    // can be picked up for translation.
    readonly property var places: [
        { key: "Home", dir: "Home", icon: "home", label: Tr.trCtx("Home", "file dialog sidebar place") },
        { key: "Downloads", dir: userDirName(StandardPaths.DownloadLocation, "Downloads"), icon: "file_download", label: Tr.trCtx("Downloads", "file dialog sidebar place") },
        { key: "Desktop", dir: userDirName(StandardPaths.DesktopLocation, "Desktop"), icon: "desktop_windows", label: Tr.trCtx("Desktop", "file dialog sidebar place") },
        { key: "Documents", dir: userDirName(StandardPaths.DocumentsLocation, "Documents"), icon: "description", label: Tr.trCtx("Documents", "file dialog sidebar place") },
        { key: "Music", dir: userDirName(StandardPaths.MusicLocation, "Music"), icon: "music_note", label: Tr.trCtx("Music", "file dialog sidebar place") },
        { key: "Pictures", dir: userDirName(StandardPaths.PicturesLocation, "Pictures"), icon: "image", label: Tr.trCtx("Pictures", "file dialog sidebar place") },
        { key: "Videos", dir: userDirName(StandardPaths.MoviesLocation, "Videos"), icon: "video_library", label: Tr.trCtx("Videos", "file dialog sidebar place") }
    ]

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
                        text: place.modelData.label
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
