pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils

import "."

ColumnLayout {
    id: root

    required property Item wrapper

    spacing: Appearance.spacing.small
    width: Config.bar.sizes.kbLayoutWidth

    KbLayoutModel {
        id: kb
    }

    function refresh() {
        kb.refresh();
    }
    Component.onCompleted: kb.start()

    StyledText {
        Layout.topMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.small
        text: qsTr("Keyboard Layouts")
        font.weight: 500
    }

    ListView {
        id: list
        model: kb.visibleModel

        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        Layout.topMargin: Appearance.spacing.small

        clip: true
        interactive: true
        implicitHeight: Math.min(contentHeight, 320)
        visible: kb.visibleModel.count > 0
        spacing: Appearance.spacing.small

        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: 140
            }
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        remove: Transition {
            NumberAnimation {
                properties: "opacity"
                to: 0
                duration: 100
            }
        }
        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

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
                enabled: !isDisabled

                function onClicked(): void {
                    if (!isDisabled)
                        kb.switchTo(layoutIndex);
                }
            }

            StyledText {
                id: rowText
                anchors.verticalCenter: layer.verticalCenter
                anchors.left: layer.left
                anchors.right: layer.right
                anchors.leftMargin: Appearance.padding.small
                anchors.rightMargin: Appearance.padding.small
                text: label
                elide: Text.ElideRight
                opacity: isDisabled ? 0.4 : 1.0
            }

            ToolTip.visible: isDisabled && layer.containsMouse
            ToolTip.text: "XKB limitation: maximum 4 layouts allowed"
        }
    }

    Rectangle {
        visible: kb.activeLabel.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        Layout.topMargin: Appearance.spacing.small

        height: 1
        color: Colours.palette.m3onSurfaceVariant
        opacity: 0.35
    }

    RowLayout {
        id: activeRow

        visible: kb.activeLabel.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.small
        Layout.topMargin: Appearance.spacing.small
        spacing: Appearance.spacing.small

        opacity: 1
        scale: 1

        MaterialIcon {
            text: "keyboard"
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            text: kb.activeLabel
            elide: Text.ElideRight
            font.weight: 500
            color: Colours.palette.m3primary
        }

        Connections {
            target: kb
            function onActiveLabelChanged() {
                if (!activeRow.visible)
                    return;
                popIn.restart();
            }
        }

        SequentialAnimation {
            id: popIn
            running: false

            ParallelAnimation {
                NumberAnimation {
                    target: activeRow
                    property: "opacity"
                    to: 0.0
                    duration: 70
                }
                NumberAnimation {
                    target: activeRow
                    property: "scale"
                    to: 0.92
                    duration: 70
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: activeRow
                    property: "opacity"
                    to: 1.0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: activeRow
                    property: "scale"
                    to: 1.0
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }
        }
    }
}
