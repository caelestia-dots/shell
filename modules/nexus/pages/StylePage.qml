pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.hallownest
import qs.components.widgets
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Style")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Style")
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium
            columns: 4
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            Repeater {
                model: Hallownest.styleNames

                StylePreview {}
            }
        }

        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: flavourRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: flavourRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Flavour")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Accent within the style")
                        color: Hallownest.subtext
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                Repeater {
                    model: Hallownest.flavours

                    Item {
                        id: flavourSlot

                        required property string modelData
                        readonly property color toneColour: Hallownest.styleData.flavours[modelData].accent

                        implicitWidth: flavourBtn.implicitWidth
                        implicitHeight: flavourBtn.implicitHeight

                        Rectangle {
                            id: flavourRing

                            anchors.centerIn: parent
                            width: Math.max(parent.width, parent.height)
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.width: 1.5
                            border.color: flavourSlot.toneColour
                            opacity: 0
                            scale: 0.7

                            ParallelAnimation {
                                id: ringAnim

                                NumberAnimation {
                                    target: flavourRing
                                    property: "scale"
                                    from: 0.65
                                    to: 1.45
                                    duration: 420
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: flavourRing
                                    property: "opacity"
                                    from: 0.7
                                    to: 0
                                    duration: 420
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        HkButton {
                            id: flavourBtn

                            implicitHeight: 28
                            text: flavourSlot.modelData.charAt(0).toUpperCase() + flavourSlot.modelData.slice(1)
                            accent: flavourSlot.toneColour
                            tinted: Hallownest.flavour === flavourSlot.modelData
                            onClicked: {
                                ringAnim.restart();
                                Hallownest.setFlavour(flavourSlot.modelData);
                            }
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Wallpaper")
        }

        ClipRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.medium
            implicitWidth: implicitHeight / root.nState.screen.height * root.nState.screen.width
            implicitHeight: Math.min(Math.round(root.cappedWidth * 0.36), root.cappedWidth / root.nState.screen.width * root.nState.screen.height)
            color: Hallownest.card
            radius: Tokens.rounding.large

            MaterialIcon {
                anchors.centerIn: parent
                visible: !Config.background.wallpaperEnabled
                text: "hide_image"
                color: Hallownest.faint
                fontStyle: Tokens.font.icon.extraLarge
            }

            WallpaperImpl {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }
        }

        NavRow {
            first: true
            icon: "wallpaper"
            text: Tr.tr("Wallpapers")
            subtext: Tr.tr("Pick an image or a folder")
            disabled: !Config.background.wallpaperEnabled
            onClicked: root.nState.openSubPage(1)
        }

        ToggleRow {
            text: Tr.tr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Transparency")
            // TRANSLATORS: %1/%2 = opacity values from 0 to 1 for the base surface and layered surfaces
            subtext: Tr.tr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }
    }

    // Miniature of a style drawn with its own colours, so every card shows what it will look like
    component StylePreview: Rectangle {
        id: preview

        required property string modelData
        readonly property var info: Hallownest.styles[modelData]
        readonly property var tone: info.flavours[Hallownest.flavour]
        readonly property bool current: Hallownest.style === modelData

        Layout.fillWidth: true
        implicitHeight: 104
        radius: Tokens.rounding.large
        color: info.base.void
        border.width: current ? 2 : 1
        border.color: current ? Hallownest.soul : area.containsMouse ? Qt.alpha(Hallownest.soul, 0.4) : Hallownest.border

        Behavior on border.color {
            CAnim {}
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            height: 40
            radius: 10
            color: preview.info.base.card
            border.width: 1
            border.color: Qt.alpha(preview.tone.steel, 0.2)

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                width: 20
                height: 20
                radius: 10
                color: preview.tone.accent
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 36
                anchors.rightMargin: 8
                spacing: 4

                Rectangle {
                    width: parent.width * 0.8
                    height: 4
                    radius: 2
                    color: preview.info.base.text
                }

                Rectangle {
                    width: parent.width * 0.5
                    height: 4
                    radius: 2
                    color: preview.info.base.subtext
                }
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            text: preview.info.name
            color: preview.current ? preview.tone.accent : preview.info.base.text
            font.family: Hallownest.serif
            font.pointSize: 11
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hallownest.setStyle(preview.modelData)
        }
    }
}
