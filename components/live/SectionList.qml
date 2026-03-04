pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var items

    Repeater {
        id: itemList

        model: root.items

        delegate: ColumnLayout {
            id: listItem

            required property var modelData
            required property int index

            Layout.fillWidth: true

            spacing: Appearance.spacing.small

            RowLayout {
                spacing: Appearance.spacing.normal

                ColumnLayout {
                    StyledText {
                        font.bold: true
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3primary
                        text: listItem.modelData.title
                    }

                    StyledText {
                        Layout.fillWidth: true

                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                        text: listItem.modelData.desc
                    }
                }

                TextButton {
                    visible: listItem.modelData.tourId ? true : false
                    text: qsTr("Show Me")
                    radius: Appearance.rounding.small
                    onClicked: Tour.startTour(listItem.modelData.tourId)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: Appearance.padding.small
                Layout.bottomMargin: Appearance.padding.small
                color: Colours.palette.m3outlineVariant
                opacity: 0.3
                visible: listItem.index < itemList.count - 1
            }
        }
    }
}
