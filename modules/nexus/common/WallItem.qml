pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.utils

Item {
    id: root

    property string source
    property alias text: label.text
    property alias radius: imgWrapper.radius
    property alias imgHeight: imgWrapper.implicitHeight
    property bool fillLabel: true

    readonly property bool isVideo: Images.isVideoFile(root.source)
    readonly property string thumbnailPath: {
        if (!root.isVideo)
            return root.source;
        const i = root.source.lastIndexOf('/');
        const dir = root.source.substring(0, i);
        const name = root.source.substring(i + 1).replace(/\.[^.]+$/, '');
        return `${dir}/.thumbs/${name}.jpg`;
    }

    signal clicked

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: imgWrapper

            Layout.fillWidth: true
            implicitHeight: width
            radius: Tokens.rounding.largeIncreased
            color: Colours.tPalette.m3surfaceContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: root.isVideo ? "videocam" : "image"
                color: Colours.tPalette.m3outline
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
            }

            Image {
                id: img

                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                source: root.thumbnailPath
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(width * dpr, height * dpr);
                }
                retainWhileLoading: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            StyledRect {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 4
                radius: Tokens.rounding.small
                color: "#CC000000"
                implicitWidth: badgeIcon.implicitWidth + 8
                implicitHeight: badgeIcon.implicitHeight + 4

                MaterialIcon {
                    id: badgeIcon

                    anchors.centerIn: parent
                    text: root.isVideo ? "videocam" : "image"
                    color: "white"
                    fontStyle: Tokens.font.icon.builders.small.scale(1).build()
                }
            }

            StyledRect {
                anchors.centerIn: parent
                visible: root.isVideo && img.status === Image.Error
                radius: Tokens.rounding.full
                color: Colours.palette.m3primaryContainer
                implicitWidth: fallbackIcon.implicitWidth + Tokens.padding.large * 2
                implicitHeight: fallbackIcon.implicitHeight + Tokens.padding.large * 2

                MaterialIcon {
                    id: fallbackIcon

                    anchors.centerIn: parent
                    text: "play_circle"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.builders.medium.scale(1.5).build()
                }
            }
        }

        StyledText {
            id: label

            Layout.bottomMargin: Tokens.padding.small
            Layout.fillWidth: true
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.builders.small.weight(Font.Medium).build()
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    StateLayer {
        anchors.bottomMargin: root.fillLabel ? 0 : layout.implicitHeight - imgWrapper.implicitHeight
        onClicked: root.clicked()
    }
}
