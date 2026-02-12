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
                        text: "Things to do before you start your journey."
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: prerequisitesSection1.height + Appearance.padding.large * 2
                        Layout.topMargin: Appearance.padding.normal
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal

                        StyledText {
                            id: prerequisitesSection1
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
