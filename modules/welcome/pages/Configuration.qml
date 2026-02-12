import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.containers
import qs.config
import "../components"

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

        // Vertical navigation
        VerticalNav {
            id: verticalNav

            Layout.fillHeight: true
            Layout.preferredWidth: 200

            sections: root.subsections
            activeSection: root.currentSubsection
            onSectionChanged: sectionId => root.currentSubsection = sectionId
        }

        // Content area
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
                        Layout.preferredHeight: settingsSection1.height + Appearance.padding.large * 2
                        Layout.topMargin: Appearance.padding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        StyledText {
                            id: settingsSection1
                            anchors.centerIn: parent
                            text: "Content coming soon:\n• System requirements\n• Installation steps\n• Dependencies"
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
