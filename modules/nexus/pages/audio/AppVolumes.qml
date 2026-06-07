pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("App volumes")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Adjust the volume of individual apps currently playing audio.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: streamList

            first: true
            last: true
            showList: true
            placeholderIcon: "music_off"
            placeholderText: qsTr("No apps playing audio")
            color: list.count === 0 ? Colours.tPalette.m3surfaceContainer : "transparent"
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...Audio.streams]
            }

            delegate: SliderRow {
                id: stream

                required property PwNode modelData
                required property int index

                anchors.left: streamList.list.contentItem.left
                anchors.right: streamList.list.contentItem.right
                first: index === 0
                last: index === streamList.list.count - 1

                icon: Icons.getVolumeIcon(stream.modelData?.audio?.volume ?? 0, stream.modelData?.audio?.muted ?? false)
                label: Audio.getStreamName(stream.modelData)
                valueLabel: Math.round(value * 100) + "%"
                value: stream.modelData?.audio?.volume ?? 0
                enabled: !stream.modelData?.audio?.muted
                onMoved: v => Audio.setStreamVolume(stream.modelData, v)
            }
        }
    }
}
