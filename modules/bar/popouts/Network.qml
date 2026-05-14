pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    property string view: "wireless" // "wireless" or "ethernet"

    spacing: Tokens.spacing.small
    width: Tokens.sizes.bar.networkWidth

    // ── Wireless status ────────────────────────────────────────────────────

    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.normal : 0
        Layout.rightMargin: Tokens.padding.small
        text: qsTr("Wireless")
        font.weight: 500
    }

    RowLayout {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.padding.normal
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: {
                if (!NetworkBackend.wifiEnabled)
                    return "wifi_off";
                if (NetworkBackend.active)
                    return Icons.getNetworkIcon(NetworkBackend.active.strength ?? 0);
                return "wifi_off";
            }
            color: NetworkBackend.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (!NetworkBackend.wifiEnabled)
                        return qsTr("WiFi disabled");
                    if (NetworkBackend.active)
                        return NetworkBackend.active.ssid;
                    return qsTr("Not connected");
                }
                font.weight: NetworkBackend.active ? 500 : 400
                color: NetworkBackend.active ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }

            StyledText {
                visible: NetworkBackend.wifiEnabled && NetworkBackend.active !== null
                Layout.preferredHeight: visible ? implicitHeight : 0
                text: {
                    if (!NetworkBackend.active)
                        return "";
                    const security = NetworkBackend.active.isSecure ? qsTr("Secured") : qsTr("Open");
                    return qsTr("%1% · %2").arg(NetworkBackend.active.strength).arg(security);
                }
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.small
            }
        }
    }

    // ── Ethernet status ────────────────────────────────────────────────────

    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.normal : 0
        Layout.rightMargin: Tokens.padding.small
        text: qsTr("Ethernet")
        font.weight: 500
    }

    RowLayout {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.padding.normal
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "cable"
            color: NetworkBackend.activeEthernet ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            text: NetworkBackend.activeEthernet ? NetworkBackend.activeEthernet.interface : qsTr("Not connected")
            font.weight: NetworkBackend.activeEthernet ? 500 : 400
            color: NetworkBackend.activeEthernet ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }
    }
}
