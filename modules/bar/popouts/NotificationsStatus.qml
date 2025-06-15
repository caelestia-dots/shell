import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        text: Notifs.notificationsEnabled ? qsTr("Notifications are enabled") : qsTr("Notifications are disabled")
    }
}
