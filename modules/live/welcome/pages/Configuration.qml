import QtQuick
import QtQuick.Layouts
import qs.services
import QtQuick.VectorImage
import qs.components
import qs.modules.live.components
import qs.components.containers
import qs.config
import "../../components"

Item {
    id: root

    readonly property list<var> subsections: [
        {
            id: "settings",
            name: qsTr("Settings App"),
            icon: "settings"
        },
        {
            id: "cli",
            name: qsTr("CLI"),
            icon: "terminal"
        },
        {
            id: "shell",
            name: qsTr("Shell"),
            icon: "desktop_windows"
        },
        {
            id: "hyprland",
            name: qsTr("Hyprland"),
            icon: "select_window"
        },
    ]

    property string currentSubsection: subsections[0].id

    function scrollToSubsection(subsectionId: string): void {
        const sectionIndex = subsections.findIndex(s => s.id === subsectionId);

        if (sectionIndex === -1) {
            contentFlickable.contentY = 0;
            return;
        }

        const targetY = sectionIndex * contentFlickable.height;
        contentFlickable.contentY = targetY;
    }

    onCurrentSubsectionChanged: scrollToSubsection(currentSubsection)

        RowLayout {
            anchors.fill: parent
            spacing: Appearance.spacing.large

       
        VerticalNav {
            id: verticalNav
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: 175
            Layout.preferredWidth: 200

            sections: root.subsections
            activeSection: root.currentSubsection
            onSectionChanged: sectionId => root.currentSubsection = sectionId
        }
        Item {
            Layout.fillHeight: true
            }

       
        StyledFlickable {
            id: contentFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.height
            flickableDirection: Flickable.VerticalFlick
            clip: true

            Behavior on contentY {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            ColumnLayout {
                id: contentColumn

                width: parent.width
                spacing: 0

            ColumnLayout {
                id: settingsSection

                Layout.fillWidth: true
                Layout.minimumHeight: contentFlickable.height
                Layout.leftMargin: Appearance.padding.larger
                Layout.rightMargin: Appearance.padding.larger
                Layout.topMargin: Appearance.padding.larger
                spacing: Appearance.padding.large

            StyledText {
                text: "Settings App"
                font.pointSize: Appearance.font.size.extraLarge
                font.bold: true
                color: Colours.palette.m3onBackground
                    }

            StyledText {
                Layout.fillWidth: true
                text: "Quick configuration for the most common shell options."
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
                    }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: taskbarContent.implicitHeight + 60
                color: Colours.palette.m3surfaceContainerLow
                radius: Appearance.rounding.normal
                border.color: Colours.palette.m3outlineVariant

           ColumnLayout {
                id: taskbarContent
                anchors.fill: parent
                anchors.margins: appearance.padding.larger
                spacing: appearance.spacing.large

            Repeater {
                model: [
                    { title: "Network", desc: "This page is dedicated to setting up your network access and VPN." },
                    { title: "Bluetooth", desc: "Configure and look for bluetooth devices here." },
                    { title: "Audio", desc: "Plugged in speakers or headphones? set up app specific volume limits." },
                    { title: "Appearance", desc: "Adjust transparency, fonts, and color variants." },
                    { title: "Taskbar", desc: "Infinitely configurable system statuses (WiFi, Battery) with expanded hover menus. Or hidden completely" },
                    { title: "Launcher", desc: "Make sure your favorite apps stay at the top! Or hide apps you dont need visible." },
                    { title: "Dashboard", desc: "Choose to disable or adjust sensitivity. Can also change what is displayed." },
                ]

                delegate: ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                StyledText {
                    text: modelData.title
                    font.bold: true
                    font.pointSize: 11
                    color: Colours.palette.m3primary
                    }

                StyledText {
                    Layout.fillWidth: true
                    text: modelData.desc
                    font.pointSize: 10
                    color: Colours.palette.m3onSurface
                    wrapMode: Text.WordWrap
                    opacity: 0.8
                    }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colours.palette.m3outlineVariant
                    opacity: 0.3
                    visible: index < 7
                    }
                }
            }
        }
    }

                Item {
                    Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    id: cliSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                StyledText {
                    text: "CLI Configuration"
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                    color: Colours.palette.m3onBackground
                    }

                StyledText {
                    Layout.fillWidth: true
                    text: "Customize the behavior of the caelestia CLI app."
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: cliSection1.height + Appearance.padding.large * 2
                    Layout.topMargin: Appearance.padding.normal
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                    radius: Appearance.rounding.normal

                StyledText {
                    id: cliSection1
                    anchors.centerIn: parent
                    text: "Content coming soon:\n• Configuration files\n• CLI usage\n• Theme customization"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                        }
                    }

                Item {
                    Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    id: shellSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                StyledText {
                    text: "Shell Configuration"
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                    color: Colours.palette.m3onBackground
                    }

                StyledText {
                    Layout.fillWidth: true
                    text: "Take your rice further with in-depth customization of the shell."
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: shellSection1.height + Appearance.padding.large * 2
                    Layout.topMargin: Appearance.padding.normal
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                    radius: Appearance.rounding.normal

                StyledText {
                    id: shellSection1
                    anchors.centerIn: parent
                    text: "Content coming soon:\n• Basic navigation\n• Keyboard shortcuts\n• Quick tips"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                        }
                    }

                Item {
                    Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    id: hyprlandSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                StyledText {
                    text: "Hyprland Configuration"
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                    color: Colours.palette.m3onBackground
                    }

                StyledText {
                    Layout.fillWidth: true
                    text: "Tweak the underlying Hyprland configuration to suit your needs."
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: hyprlandSection1.height + Appearance.padding.large * 2
                    Layout.topMargin: Appearance.padding.normal
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                    radius: Appearance.rounding.normal

                StyledText {
                    id: hyprlandSection1
                    anchors.centerIn: parent
                    text: "Content coming soon:\n• Basic navigation\n• Keyboard shortcuts\n• Quick tips"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                        }
                    }

                Item {
                    Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
