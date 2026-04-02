pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.components
import qs.services
import qs.config

Column {
    id: root

    spacing: Appearance.spacing.normal

    Repeater {
        model: ScriptModel {
            values: MailService.unreadEmails.slice(0,5)
        }

        Row {
            id: emails

            required property var modelData

            spacing: Appearance.spacing.small

            MaterialIcon {
                id: icon

                animate: true

                text: "mail"
                color: Colours.palette.m3onSurface
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
              text: modelData?.author + ": " ?? ""
              anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: modelData?.subject ?? ""
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            } 
        }
    }
}
