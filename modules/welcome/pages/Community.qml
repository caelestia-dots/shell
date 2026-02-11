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
                            spacing: Appearance.padding.large

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Need help or support? Want to chat with other Caelestia users? The official Caelestia Discord community is an active community that is growing daily! Why not stop in and say hi?")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large

                                TextButton {
                                    text: qsTr("Join Discord")
                                    radius: Appearance.rounding.small

                                    onClicked: Qt.openUrlExternally("https://discord.gg/BGDCFCmMBk")
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
