pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.config

import "."

ColumnLayout {
    id: root
    spacing: Appearance.spacing.normal

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    KbLayoutModel { id: kb }

    function refresh() { kb.refresh() }

    Component.onCompleted: kb.start()

    Column {
        id: content
        spacing: Appearance.spacing.normal
        Layout.fillWidth: true

        StyledText {
            text: qsTr("Keyboard Layouts")
            font.weight: 600
            padding: Appearance.padding.small
        }

        ListView {
            id: list
            model: kb.visibleModel
            clip: true
            interactive: true
            implicitWidth: Math.max(240, contentWidth)
            implicitHeight: Math.min(contentHeight, 320)
            visible: kb.visibleModel.count > 0

            delegate: Item {
                required property int layoutIndex
                required property string label

                width: list.width
                height: Math.max(36, rowText.implicitHeight + Appearance.padding.small * 2)

                readonly property bool isDisabled: layoutIndex > 3

                StateLayer {
                    id: layer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: parent.height - 4
                    radius: Appearance.rounding.full
                    color: Colours.palette.m3primary

                    enabled: !isDisabled
                    opacity: isDisabled ? 0.4 : 1.0

                    function onClicked(): void {
                        if (!isDisabled)
                            kb.switchTo(layoutIndex);
                    }
                }

                StyledText {
                    id: rowText
                    anchors.verticalCenter: layer.verticalCenter
                    anchors.left: layer.left
                    anchors.leftMargin: Appearance.padding.small
                    text: label
                    opacity: layer.opacity
                }

                ToolTip.visible: isDisabled && mouse.containsMouse
                ToolTip.text: "XKB limitation: maximum 4 layouts allowed"

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: false
                }
            }
        }

        Rectangle {
            visible: kb.activeLabel.length > 0
            width: parent.width
            height: 1
            color: Colours.palette.m3onSurfaceVariant
            opacity: 1.0
        }

        Item {
            visible: kb.activeLabel.length > 0
            width: parent.width
            height: Math.max(36, footerText.implicitHeight + Appearance.padding.small * 2)

            StyledText {
                id: footerText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.small
                text: kb.activeLabel
                opacity: 0.85
                font.weight: 500
            }
        }
    }
}
