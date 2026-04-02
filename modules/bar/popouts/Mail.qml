pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.config

Column {
    id: root

    spacing: Appearance.spacing.normal

    Repeater {
        model: ScriptModel {
            values: MailService.unreadEmails.slice(0, Math.min(Config.bar.mail.emailsShown, 15))
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
              text: emails.modelData?.author + ": " ?? ""
              anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: emails.modelData?.subject ?? ""
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            } 
        }
    }
}
