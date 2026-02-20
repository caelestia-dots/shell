import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.config
import "../components"

Item {
    id: root

    readonly property list<var> subsections: [
        {
            id: "joinUs",
            name: qsTr("Join Us"),
            icon: "forum"
        },
        {
            id: "getInvolved",
            name: qsTr("Get Involved"),
            icon: "code"
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
            Layout.preferredHeight: 90
            Layout.preferredWidth: 200

            sections: root.subsections
            activeSection: root.currentSubsection
            onSectionChanged: sectionId => root.currentSubsection = sectionId
        }
        Item {
                        Layout.fillHeight: true
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
                    id: joinUsSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    Layout.topMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    StyledText {
                        text: qsTr("Join Us")
                        font.pointSize: Appearance.font.size.extraLarge
                        font.bold: true
                        color: Colours.palette.m3onBackground
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Join our thriving community on Discord.")
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: joinUsContent.height + Appearance.padding.large * 2
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        RowLayout {
                            anchors.fill: parent

                            StyledText {
                                id: joinUsContent

                                Layout.fillWidth: true
                                Layout.margins: Appearance.padding.large
                                text: qsTr("Need help or support? Want to chat with other Caelestia users? The official Caelestia Discord community is an active community that is growing daily! Why not stop in and say hi?")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            TextButton {
                                Layout.margins: Appearance.padding.large
                                Layout.alignment: Qt.AlignVCenter
                                text: qsTr("Join Discord")
                                radius: Appearance.rounding.small

                                onClicked: Qt.openUrlExternally("https://discord.gg/BGDCFCmMBk")
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    id: getInvolvedSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    Layout.topMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    StyledText {
                        text: qsTr("Get Involved")
                        font.pointSize: Appearance.font.size.extraLarge
                        font.bold: true
                        color: Colours.palette.m3onBackground
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Become a contributor.")
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }

                    StyledRect {
                        Layout.preferredHeight: getInvolvedContent.height + Appearance.padding.large
                        Layout.fillWidth: true
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        ColumnLayout {
                            id: getInvolvedContent

                            width: parent.width

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia might have had humble beginnings, but today we have a growing number of contributors. Whether you have a bug to report, a bugfix you want to contribute, or a feature request, we'd love to hear from you!")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    StyledRect {
                        Layout.preferredHeight: getInvolvedContent2.height + Appearance.padding.large
                        Layout.fillWidth: true
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        ColumnLayout {
                            id: getInvolvedContent2

                            width: parent.width
                            spacing: Appearance.padding.large

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia CLI")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia CLI is the main control script for Caelestia. Written in Python, CLI is responsible for the caelestia command, which acts as a handler for functionality such as schemes, wallpaper management, and screen capture and recording.")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia Shell")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia Shell provides the actual UI elements and much of the underlying functionality of Caelestia. It is primarily written in QML, and built around Quickshell.")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia Dots")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia Dots is the main repo for Caelestia, and handles all of the application configs, as well as the Caelestia install script. This is the primary point of entry for most users, and serves as the primary installation guide for Caelestia.")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia Live")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia Live is the unofficial community project to build a Caelestia-based live image. If you're reading this, congratulations! You're running Caelestia Live! Caelestia Live was built by Evertiro, and at this time, he provides all live-image specific support.")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    StyledRect {
                        Layout.preferredHeight: getInvolvedContent3.height + Appearance.padding.large
                        Layout.fillWidth: true
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        ColumnLayout {
                            id: getInvolvedContent3

                            width: parent.width

                            RowLayout {
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                spacing: Appearance.padding.large

                                TextButton {
                                    text: qsTr("Caelestia CLI")
                                    radius: Appearance.rounding.small

                                    onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/cli")
                                }

                                TextButton {
                                    text: qsTr("Caelestia Shell")
                                    radius: Appearance.rounding.small

                                    onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/shell")
                                }

                                TextButton {
                                    text: qsTr("Caelestia Dots")
                                    radius: Appearance.rounding.small

                                    onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/caelestia")
                                }

                                TextButton {
                                    text: qsTr("Caelestia Live")
                                    radius: Appearance.rounding.small

                                    onClicked: Qt.openUrlExternally("https://github.com/caelestia-community/live")
                                }
                            }
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
