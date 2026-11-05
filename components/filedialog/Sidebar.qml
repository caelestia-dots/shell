pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.utils

Item {
    id: root

    required property DialogState dState

    implicitWidth: Tokens.sizes.fileDialog.sidebarWidth
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

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
            font: Tokens.font.title.medium
        }

        Place {
            path: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.HomeLocation)).split("/")
            icon: "home"
            label: Tr.trCtx("Home", "file location")
        }

        Place {
            path: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.DesktopLocation)).split("/")
            icon: "desktop_windows"
            label: Tr.trCtx("Desktop", "file location")
        }

        Place {
            path: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.DocumentsLocation)).split("/")
            icon: "description"
            label: Tr.trCtx("Documents", "file location")
        }

        Place {
            path: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.DownloadLocation)).split("/")
            icon: "file_download"
            label: Tr.trCtx("Downloads", "file location")
        }

        Place {
            path: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.MusicLocation)).split("/")
            icon: "music_note"
            label: Tr.trCtx("Music", "file location")
        }

        Place {
            path: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.PicturesLocation)).split("/")
            icon: "image"
            label: Tr.trCtx("Pictures", "file location")
        }

        Place {
            path: Paths.toLocalFile(StandardPaths.writableLocation(StandardPaths.MoviesLocation)).split("/")
            icon: "video_library"
            label: Tr.trCtx("Videos", "file location")
        }
    }

    component Place: StyledRect {
        id: place

        required property list<string> path
        required property string icon
        required property string label
        readonly property bool selected: path.join("/") === root.dState.cwd.join("/")

        Layout.fillWidth: true
        implicitHeight: placeInner.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.full
        color: Qt.alpha(Colours.palette.secondaryContainer, selected ? 1 : 0)

        StateLayer {
            color: place.selected ? Colours.palette.onSecondaryContainer : Colours.palette.onSurface
            onClicked: root.dState.cdTo(place.path)
        }

        RowLayout {
            id: placeInner

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.large

            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: place.icon
                color: place.selected ? Colours.palette.onSecondaryContainer : Colours.palette.onSurfaceVariant
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
                text: place.label
                color: place.selected ? Colours.palette.onSecondaryContainer : Colours.palette.onSurface
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }
    }
}
