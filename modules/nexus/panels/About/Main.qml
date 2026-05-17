pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property int activeTabIndex: 0

    property string hostname: ""
    property string quickshellVersion: ""
    property string qtVersion: ""
    property string distroName: ""
    property string distroVersion: ""
    property string kernelVersion: ""
    property string shellVersion: ""
    property string cliVersion: ""
    property string deviceName: ""
    property string firmwareVersion: ""

    readonly property string shellGitPath: {
        const url = Qt.resolvedUrl(".");
        const path = url.toString().replace(/^file:\/\//, "");
        const parts = path.split("/");
        parts.splice(-5);
        const resolved = parts.join("/");
        return resolved;
    }

    FileView {
        id: hostnameFile

        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }

    FileView {
        id: osRelease

        path: "/etc/os-release"
        onLoaded: {
            const content = text();
            const nameMatch = content.match(/^PRETTY_NAME="([^"]+)"/m);
            const idMatch = content.match(/^ID="([^"]+)"/m);
            const versionMatch = content.match(/^VERSION_ID="([^"]+)"/m);
            const nameLikeMatch = content.match(/^NAME="([^"]+)"/m);

            if (nameMatch) {
                root.distroName = nameMatch[1];
            } else if (nameLikeMatch) {
                root.distroName = nameLikeMatch[1];
            } else if (idMatch) {
                root.distroName = idMatch[1];
            } else {
                root.distroName = "Unknown";
            }

            if (versionMatch) {
                root.distroVersion = versionMatch[1];
            } else {
                root.distroVersion = "";
            }
        }
    }

    FileView {
        id: procVersion

        path: "/proc/version"
        onLoaded: {
            const content = text();
            const match = content.match(/Linux version ([^\s]+)/);
            root.kernelVersion = match ? match[1] : "Unknown";
        }
    }

    Process {
        id: quickshellVersionProc

        command: ["quickshell", "--version"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                const match = output.match(/quickshell[\s]+([\d.]+)/i);
                root.quickshellVersion = match ? match[1] : output;
            }
        }
    }

    Process {
        id: qtVersionProc

        command: ["sh", "-c", "qmake6 --version 2>/dev/null | grep 'Qt version' | awk '{print $4}' || echo 'Unknown'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.qtVersion = text.trim() || "Unknown"
        }
    }

    Process {
        id: shellVersionProc

        command: ["sh", "-c", "git -C " + root.shellGitPath + " describe --tags 2>/dev/null || " + "caelestia -v 2>/dev/null | grep -o 'caelestia-shell [0-9.]*' | awk '{print $2}' || " + "pacman -Q caelestia-shell caelestia-shell-git 2>/dev/null | head -1 | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.shellVersion = text.trim() || "Unknown"
        }
    }

    Process {
        id: cliVersionProc

        command: ["sh", "-c", "caelestia --version 2>/dev/null | head -1 | grep -oP '[0-9.]+' || " + "pip show caelestia 2>/dev/null | grep '^Version:' | awk '{print $2}' || " + "pacman -Q caelestia-cli 2>/dev/null | awk '{print $2}' || " + "echo 'Not installed'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cliVersion = text.trim() || "Unknown"
        }
    }

    Process {
        id: deviceInfoProc

        command: ["sh", "-c", "cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo 'Unknown Device'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.deviceName = text.trim() || "Unknown Device"
        }
    }

    Process {
        id: firmwareInfoProc

        command: ["sh", "-c", "cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null || echo 'Unknown'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.firmwareVersion = text.trim() || "Unknown"
        }
    }

    ScrollView {
        id: scrollView

        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: scrollView.width

            // Header Section
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small
                Layout.bottomMargin: Tokens.padding.large * 3

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.large

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft

                        Logo {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 100
                            Layout.bottomMargin: -35
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft
                        Layout.bottomMargin: -35

                        StyledText {
                            text: "Caelestia"
                            Layout.alignment: Qt.AlignLeft
                            Layout.bottomMargin: -10
                            font.pointSize: Tokens.font.size.extraLarge + 8
                            font.weight: Font.Light
                            color: Colours.palette.m3onSurface
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignLeft
                            text: "Version " + root.shellVersion
                            font.pointSize: Tokens.font.size.normal
                            color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
                        }
                    }
                }
            }

            GridLayout {
                id: infoGrid

                Layout.fillWidth: true
                columns: width < 500 ? 1 : 2
                columnSpacing: Tokens.spacing.large * 2
                rowSpacing: Tokens.spacing.large

                // System Section
                InfoSection {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    title: "System"
                    icon: "computer"

                    InfoRow {
                        label: "Hostname"
                        value: root.hostname
                    }
                    InfoRow {
                        label: "Device"
                        value: root.deviceName
                    }
                    InfoRow {
                        label: "Distribution"
                        value: root.distroVersion ? root.distroName + " " + root.distroVersion : root.distroName
                    }
                    InfoRow {
                        label: "Kernel"
                        value: root.kernelVersion
                    }
                    InfoRow {
                        label: "Firmware"
                        value: root.firmwareVersion
                    }
                }

                // Software Section
                InfoSection {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    title: "Software"
                    icon: "code"

                    InfoRow {
                        label: "Shell"
                        value: root.shellVersion
                    }
                    InfoRow {
                        label: "CLI"
                        value: root.cliVersion
                    }
                    InfoRow {
                        label: "Quickshell"
                        value: root.quickshellVersion
                    }
                    InfoRow {
                        label: "Qt"
                        value: root.qtVersion
                    }
                    InfoRow {
                        label: "Plugins"
                        value: "0"
                    }
                }
            }

            // Links
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.padding.large * 2
                spacing: Tokens.spacing.normal

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: "link"
                        font.pointSize: Tokens.font.size.large
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: "Links"
                        font.pointSize: Tokens.font.size.large
                        font.weight: Font.Medium
                        color: Colours.palette.m3primary
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.12)
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.normal

                    LinkButton {
                        implicitWidth: 140
                        icon: "chat"
                        text: "Discord"
                        url: "https://discord.gg/BGDCFCmMBk"
                    }

                    LinkButton {
                        implicitWidth: 140
                        icon: "code"
                        text: "Shell Repo"
                        url: "https://github.com/caelestia-dots/shell"
                    }

                    LinkButton {
                        implicitWidth: 140
                        icon: "terminal"
                        text: "CLI Repo"
                        url: "https://github.com/caelestia-dots/cli"
                    }
                }
            }

            // Spacer at bottom
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.padding.large
            }
        }
    }

    // Info row component
    component InfoRow: RowLayout {
        id: infoRow

        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        StyledText {
            text: infoRow.label
            font.pointSize: Tokens.font.size.normal
            color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: infoRow.value
            font.pointSize: Tokens.font.size.normal
            font.weight: Font.Medium
            color: Colours.palette.m3onSurface
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.minimumWidth: 80
        }
    }

    // Info section component
    component InfoSection: ColumnLayout {
        id: section

        property string title: ""
        property string icon: ""
        default property alias content: contentArea.children

        spacing: Tokens.spacing.normal

        // Section header
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.normal

            MaterialIcon {
                text: section.icon
                font.pointSize: Tokens.font.size.large
                color: Colours.palette.m3primary
            }

            StyledText {
                text: section.title
                font.pointSize: Tokens.font.size.large
                font.weight: Font.Medium
                color: Colours.palette.m3primary
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(Colours.palette.m3onSurface, 0.12)
        }

        ColumnLayout {
            id: contentArea

            Layout.fillWidth: true
            spacing: Tokens.spacing.small
        }
    }

    // Link button component - smaller text, more padding
    component LinkButton: Rectangle {
        id: linkButton

        property string icon: ""
        property string text: ""
        property string url: ""

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.normal
        implicitHeight: 52

        RowLayout {
            id: linkLayout

            anchors.centerIn: parent
            spacing: Tokens.spacing.normal

            MaterialIcon {
                text: linkButton.icon
                font.pointSize: Tokens.font.size.normal
                color: Colours.palette.m3primary
            }

            StyledText {
                text: linkButton.text
                font.pointSize: Tokens.font.size.normal
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
            }
        }

        TapHandler {
            onTapped: Qt.openUrlExternally(linkButton.url)
        }

        Behavior on color {
            ColorAnimation {
                duration: Tokens.anim.durations.small
            }
        }

        HoverHandler {
            id: hoverHandler

            onHoveredChanged: linkButton.color = hovered ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer
        }
    }
}
