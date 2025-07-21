import qs.widgets
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        text: qsTr("Connected to: %1").arg(Network.active?.ssid ?? "None")
    }

    StyledText {
        text: qsTr("Strength: %1/100").arg(Network.active?.strength ?? 0)
    }

    StyledText {
        text: qsTr("Frequency: %1 MHz").arg(Network.active?.frequency ?? 0)
    }
}
