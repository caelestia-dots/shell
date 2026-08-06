import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Plugin support is not wired up yet; always 0 for now
    readonly property int pluginCount: 0

    property string quickshellVersion
    property string cliVersion

    title: qsTr("About")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // e.g. "Quickshell 0.3.0 (revision ...)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // Parsed from the caelestia CLI's package listing; the sh wrapper avoids a
        // warning when the (optional) CLI isn't installed
        Process {
            running: true
            command: ["sh", "-c", "caelestia --version 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/caelestia-cli\S*\s+(\d+(?:\.\d+)*)/);
                    root.cliVersion = m ? m[1] : "";
                }
            }
        }

        // Hero
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                AnimatedLogo {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: "Caelestia"
                    font: Tokens.font.headline.builders.large.width(110).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: CUtils.version ? `v${CUtils.version}` : "…"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        // System
        SectionHeader {
            text: qsTr("System")
        }

        InfoRow {
            first: true
            icon: "dns"
            label: qsTr("Hostname")
            value: SysInfo.hostname
        }

        InfoRow {
            icon: "computer"
            label: qsTr("Device")
            value: SysInfo.device
        }

        InfoRow {
            icon: "rocket_launch"
            label: qsTr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName
        }

        InfoRow {
            icon: "memory"
            label: qsTr("Kernel")
            value: SysInfo.kernel
        }

        InfoRow {
            last: true
            icon: "developer_board"
            label: qsTr("Firmware")
            value: SysInfo.firmware
        }

        // Software
        SectionHeader {
            text: qsTr("Software")
        }

        InfoRow {
            first: true
            label: qsTr("Shell")
            value: CUtils.version || "…"

            leadingComponent: Component {
                Item {
                    readonly property real targetSize: 20

                    implicitWidth: targetSize
                    implicitHeight: targetSize * (90.38 / 128)

                    AnimatedLogo {
                        anchors.centerIn: parent
                        skipIntroAnimation: true
                        scale: parent.targetSize / 128
                    }
                }
            }
        }

        InfoRow {
            icon: "terminal"
            label: qsTr("CLI")
            value: root.cliVersion || "…"
        }

        InfoRow {
            icon: "deployed_code"
            label: qsTr("Quickshell")
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            icon: "code"
            label: qsTr("Qt")
            value: CUtils.qtVersion || "…"
        }

        // Resources
        SectionHeader {
            text: qsTr("Resources")
        }

        InfoRow {
            first: true
            icon: "forum"
            label: qsTr("Discord")
            value: "discord.gg/Caelestia"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("https://discord.gg/HM24fh65E")
            }
        }

        InfoRow {
            last: true
            icon: "language"
            label: qsTr("Website")
            value: "www.caelestiashell.com"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("https://caelestiashell.com/")
            }
        }

        // Plugins
        SectionHeader {
            text: qsTr("Plugins")
        }

        InfoRow {
            first: true
            last: true
            icon: "extension"
            label: qsTr("Loaded plugins")
            value: root.pluginCount.toString()
        }
    }
}
