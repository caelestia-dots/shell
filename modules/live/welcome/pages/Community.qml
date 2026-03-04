import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.live
import qs.components.containers
import qs.components.controls
import qs.config

Item {
    id: root

    readonly property list<var> subsections: [
        {
            id: "join-us",
            name: qsTr("Join Us"),
            icon: "forum"
        },
        {
            id: "get-involved",
            name: qsTr("Get Involved"),
            icon: "code"
        },
    ]

    property string currentSubsection: subsections[0].id

    property bool programmaticScroll: false

    Timer {
        id: scrollTimer
        interval: Appearance.anim.durations.normal + 50
        onTriggered: root.programmaticScroll = false
    }

    function scrollToSubsection(subsectionId: string): void {
        let targetY = 0

        switch(subsectionId) {
            case "join-us":
                targetY = joinUsSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            case "get-involved":
                targetY = getInvolvedSectionHeader.mapToItem(contentColumn, 0, 0).y
                break
            default:
                targetY = 0
        }

        programmaticScroll = true
        root.currentSubsection = subsectionId
        contentFlickable.contentY = targetY
        scrollTimer.restart()
    }

    function updateCurrentSection(): void {
        if (programmaticScroll)
            return

        const sections = [
            {
                id: "join-us",
                header: joinUsSectionHeader
            },
            {
                id: "get-involved",
                header: getInvolvedSectionHeader
            }
        ]

        const scrollY = contentFlickable.contentY
        const viewportCenter = scrollY + (contentFlickable.height / 3)

        let currentSection = sections[0].id
        let minDistance = Infinity

        for (let i = 0; i < sections.length; i++) {
            const sectionY = sections[i].header.mapToItem(contentColumn, 0, 0).y
            const distance = Math.abs(sectionY - scrollY)

            if (sectionY <= viewportCenter && distance < minDistance) {
                minDistance = distance
                currentSection = sections[i].id
            }
        }

        root.currentSubsection = currentSection
    }

    RowLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.large

        ColumnLayout {
            VerticalNav {
                id: verticalNav

                Layout.alignment: Qt.AlignTop

                sections: root.subsections
                activeSection: root.currentSubsection
                onSectionChanged: sectionId => root.scrollToSubsection(sectionId)
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // Content area
        StyledFlickable {
            id: contentFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.height
            flickableDirection: Flickable.VerticalFlick
            clip: true

            onContentYChanged: root.updateCurrentSection()

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
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    SectionHeader {
                        id: joinUsSectionHeader

                        title: qsTr("Join Us")
                        subtitle: qsTr("Join our thriving community on Discord.")
                    }

                    SectionContentArea {
                        title: qsTr("Need help or support?")
                        subtitle: qsTr("Want to chat with other Caelestia users?")

                        content: Component {
                            ColumnLayout {
                                RowLayout {
                                    anchors.fill: parent

                                    StyledText {
                                        id: joinUsContent

                                        Layout.fillWidth: true
                                        Layout.rightMargin: Appearance.padding.large
                                        text: qsTr("The official Caelestia Discord community is an active community that is growing daily! Why not stop in and say hi?")
                                        font.pointSize: Appearance.font.size.normal
                                        color: Colours.palette.m3onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                    }

                                    TextButton {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: qsTr("Join Discord")
                                        radius: Appearance.rounding.small

                                        onClicked: Qt.openUrlExternally("https://discord.gg/BGDCFCmMBk")
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }

                ColumnLayout {
                    id: getInvolvedSection

                    Layout.fillWidth: true
                    Layout.margins: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    SectionHeader {
                        id: getInvolvedSectionHeader

                        title: qsTr("Get Involved")
                        subtitle: qsTr("Become a contributor.")
                    }

                    SectionContentArea {
                        content: Component {
                            ColumnLayout {
                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("Caelestia might have had humble beginnings, but today we have a growing number of contributors. Whether you have a bug to report, a bugfix you want to contribute, or a feature request, we'd love to hear from you!")
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurfaceVariant
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    SectionContentArea {
                        title: qsTr("Caelestia CLI")

                        content: Component {
                            ColumnLayout {
                                RowLayout {
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Caelestia CLI is the main control script for Caelestia. Written in Python, CLI is responsible for the caelestia command, which acts as a handler for functionality such as schemes, wallpaper management, and screen capture and recording.")
                                        font.pointSize: Appearance.font.size.normal
                                        color: Colours.palette.m3onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                    }

                                    TextButton {
                                        text: qsTr("Caelestia CLI")
                                        radius: Appearance.rounding.small

                                        onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/cli")
                                    }
                                }
                            }
                        }
                    }

                    SectionContentArea {
                        title: qsTr("Caelestia Shell")

                        content: Component {
                            ColumnLayout {
                                RowLayout {
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Caelestia Shell provides the actual UI elements and much of the underlying functionality of Caelestia. It is primarily written in QML, and built around Quickshell.")
                                        font.pointSize: Appearance.font.size.normal
                                        color: Colours.palette.m3onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                    }

                                    TextButton {
                                        text: qsTr("Caelestia Shell")
                                        radius: Appearance.rounding.small

                                        onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/shell")
                                    }
                                }
                            }
                        }
                    }

                    SectionContentArea {
                        title: qsTr("Caelestia Dots")

                        content: Component {
                            ColumnLayout {
                                RowLayout {
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Caelestia Dots is the main repo for Caelestia, and handles all of the application configs, as well as the Caelestia install script. This is the primary point of entry for most users, and serves as the primary installation guide for Caelestia.")
                                        font.pointSize: Appearance.font.size.normal
                                        color: Colours.palette.m3onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                    }

                                    TextButton {
                                        text: qsTr("Caelestia Dots")
                                        radius: Appearance.rounding.small

                                        onClicked: Qt.openUrlExternally("https://github.com/caelestia-dots/caelestia")
                                    }
                                }
                            }
                        }
                    }

                    SectionContentArea {
                        title: qsTr("Caelestia Live")

                        content: Component {
                            ColumnLayout {
                                RowLayout {
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Caelestia Live is the unofficial community project to build a Caelestia-based live image. If you're reading this, congratulations! You're running Caelestia Live! Caelestia Live was built by Evertiro, and at this time, he provides all live-image specific support.")
                                        font.pointSize: Appearance.font.size.normal
                                        color: Colours.palette.m3onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                    }

                                    TextButton {
                                        text: qsTr("Caelestia Dots")
                                        radius: Appearance.rounding.small

                                        onClicked: Qt.openUrlExternally("https://github.com/caelestia-community/live")
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Appearance.padding.larger * 3
                    }
                }
            }
        }
    }
}
