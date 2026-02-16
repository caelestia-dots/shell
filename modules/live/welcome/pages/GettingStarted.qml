import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.components.containers
import qs.modules.live.components
import qs.config

Item {
    id: root

    readonly property list<var> subsections: [
        {
            id: "prerequisites",
            name: qsTr("Prerequisites"),
            icon: "checklist"
        },
        {
            id: "installation",
            name: qsTr("Installation"),
            icon: "download"
        },
        {
            id: "first-steps",
            name: qsTr("First Steps"),
            icon: "bolt"
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
                    id: prerequisitesSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    Layout.topMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    StyledText {
                        text: "Prerequisites"
                        font.pointSize: Appearance.font.size.extraLarge
                        font.bold: true
                        color: Colours.palette.m3onBackground
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Things you need before you start your journey."
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }

                    StyledRect {
                        Layout.preferredHeight: prerequisitesSection1.height + Appearance.padding.large
                        Layout.fillWidth: true
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        ColumnLayout {
                            id: prerequisitesSection1

                            width: parent.width

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("System Requirements")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia is built on Arch Linux and by its nature does not have system requirements that are out of reach for most machines.")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Some considerations")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Caelestia does need to meet a few minimums to run WELL. though it will run on less. Currently ARM processors like SnapDragon are not officially support by Arch Linux or Caelestia.")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("-x86_64 Dual Core Processor like AMD or Intel\n-4GB of system memory(RAM)\n-256GB of Storage\n-Dedicated GPU or Modern iGPU(Iris Xe or Radeon)\n-A display that is 1024x768 or better")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                    StyledRect {
                        Layout.preferredHeight: prerequisitesSection2.height + Appearance.padding.large
                        Layout.fillWidth: true
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        ColumnLayout {
                            id: prerequisitesSection2

                            width: parent.width

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("Personal Requirements")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("This isn't Windows and doesnt pretend to be. Linux and by extension Caelestia is a totally different way of interacting with and experiencing your PC. without limits and without bloat. Your PC is your PC(imagine that), everything you do to your machine belongs to you and is present because you put it there. No accounts, no 'sign-in to use', and no spyware unless you ask for it!")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("An apptitude for Learning!")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("While we have a great community to help and teach. I am sure you will be find some things challenging. It is an expectation that you will learn and grow, not outsource all your troubleshooting to a hivemind or AI overlord. Copy exact is great for consistency, but you are unique and your computer experience should be as well. Never Stop Learning!")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: Appearance.padding.large
                                Layout.leftMargin: Appearance.padding.large
                                Layout.rightMargin: Appearance.padding.large
                                text: qsTr("I am always doing that which I cannot do, in order that I may learn how to do it. — Pablo Picasso.")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }


                    Item {
                        Layout.fillHeight: true
                    }
                }

                ColumnLayout {
                    id: installationSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    StyledText {
                        text: "Installation"
                        font.pointSize: Appearance.font.size.extraLarge
                        font.bold: true
                        color: Colours.palette.m3onBackground
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Taking your computer from raw to riced!"
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: installationSection1.height + Appearance.padding.large * 2
                        Layout.topMargin: Appearance.padding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        StyledText {
                            id: installationSection1
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
                    id: firstStepsSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    StyledText {
                        text: "First Steps"
                        font.pointSize: Appearance.font.size.extraLarge
                        font.bold: true
                        color: Colours.palette.m3onBackground
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Learn the basics and start exploring Caelestia's features."
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: firstStepsSection1.height + Appearance.padding.large * 2
                        Layout.topMargin: Appearance.padding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        StyledText {
                            id: firstStepsSection1
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
