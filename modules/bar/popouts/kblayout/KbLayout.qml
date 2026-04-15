pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    function refresh() {
        kb.refresh();
    }

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.kbLayoutWidth

    Component.onCompleted: kb.start()

    KbLayoutModel {
        id: kb
    }

    StyledText {
        Layout.topMargin: Tokens.padding.normal
        Layout.rightMargin: Tokens.padding.small
        text: qsTr("Keyboard Layouts")
        font.weight: 500
    }

    ListView {
        id: list

        model: kb.visibleModel

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.small
        Layout.topMargin: Tokens.spacing.small

        clip: true
        interactive: true
        implicitHeight: Math.min(contentHeight, 320)
        visible: kb.visibleModel.count > 0
        spacing: Tokens.spacing.small

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
            id: kbDelegate

            required property int layoutIndex
            required property string label
            readonly property bool isDisabled: layoutIndex > 3

            width: list.width
            height: Math.max(36, rowText.implicitHeight + Tokens.padding.small * 2)
            ToolTip.visible: isDisabled && layer.containsMouse
            ToolTip.text: "XKB limitation: maximum 4 layouts allowed"

            StateLayer {
                id: layer

                function onClicked(): void {
                    if (!kbDelegate.isDisabled)
                        kb.switchTo(kbDelegate.layoutIndex);
                }

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height - 4
                radius: Tokens.rounding.full
                enabled: !kbDelegate.isDisabled
            }

            StyledText {
                id: rowText

                anchors.verticalCenter: layer.verticalCenter
                anchors.left: layer.left
                anchors.right: layer.right
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                text: kbDelegate.label
                elide: Text.ElideRight
                opacity: kbDelegate.isDisabled ? 0.4 : 1.0
            }
        }
    }

    Rectangle {
        visible: kb.activeLabel.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.small
        Layout.topMargin: Tokens.spacing.small

        implicitHeight: 1
        color: Colours.palette.m3onSurfaceVariant
        opacity: 0.35
    }

    RowLayout {
        id: activeRow

        visible: kb.activeLabel.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.small
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

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
            function onActiveLabelChanged() {
                if (!activeRow.visible)
                    return;
                popIn.restart();
            }

            target: kb
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
