import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        text: Notifs.notificationsEnabled ? "Notifications are enabled" : "Notifications are disabled"
    }

    StyledText {
        text: Notifs.notificationsEnabled ? `You have ${Notifs.popups.length} Notifications` : `You have ${Notifs.pending.length} Notifications`
    }
}
