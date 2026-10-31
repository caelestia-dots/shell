pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import Caelestia.Scheme
import qs.components.controls

ButtonRow {
    id: root

    required property NotifData notif

    readonly property color buttonColour: notif.urgency === NotifData.Critical ? Colours.palette.secondary : Colours.layer(Colours.palette.surfaceContainerHighest, 2)
    readonly property color buttonTextColour: notif.urgency === NotifData.Critical ? Colours.palette.onSecondary : Colours.palette.onSurfaceVariant

    function invoke(action: var): void {
        action.invoke();
        if (!notif.resident)
            notif.dismiss();
    }

    spacing: Tokens.spacing.extraSmall

    IconButton {
        isRound: true
        shapeMorph: true
        fillWidth: root.notif.actions.length === 0
        inactiveColour: root.buttonColour
        inactiveOnColour: root.buttonTextColour
        icon: "close"
        padding: Tokens.padding.extraSmall
        onClicked: root.notif.dismiss()
    }

    Repeater {
        model: root.notif.actions

        delegate: root.notif.hasActionIcons ? iconAction : textAction
    }

    IconButton {
        isRound: true
        shapeMorph: true
        fillWidth: root.notif.actions.length === 0
        inactiveColour: root.buttonColour
        inactiveOnColour: root.buttonTextColour
        icon: copyTimer.running ? "inventory" : "content_copy"
        padding: Tokens.padding.extraSmall
        onClicked: {
            Quickshell.clipboardText = root.notif.body;
            copyTimer.restart();
        }
        label.animate: true

        Timer {
            id: copyTimer

            interval: 3000
        }
    }

    Component {
        id: textAction

        TextButton {
            required property var modelData

            isRound: true
            shapeMorph: true
            fillWidth: true
            inactiveColour: root.buttonColour
            inactiveOnColour: root.buttonTextColour
            text: modelData.text
            onClicked: root.invoke(modelData)

            label.horizontalAlignment: Text.AlignHCenter
            label.anchors.left: left
            label.anchors.right: right
            label.anchors.verticalCenter: verticalCenter
            label.anchors.centerIn: undefined
            label.anchors.margins: Tokens.padding.medium
            label.elide: Text.ElideRight
        }
    }

    Component {
        id: iconAction

        ButtonBase {
            id: button

            required property var modelData

            isRound: true
            shapeMorph: true
            fillWidth: true
            padding: Tokens.padding.extraSmall
            inactiveColour: root.buttonColour
            inactiveOnColour: root.buttonTextColour
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + padding * 2
            onClicked: root.invoke(modelData)

            IconImage {
                id: icon

                anchors.centerIn: parent
                implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                asynchronous: true
                source: Quickshell.iconPath(button.modelData.identifier)
            }
        }
    }
}
