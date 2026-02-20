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
        {
          id: "workspaces",
          name:qsTr("Workspaces"),
          icon: "stack"
        }
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
                        Layout.fillWidth: true
                        Layout.preferredHeight: prerequisitesColumn.implicitHeight + (Appearance.padding.large * 2)
                        // Using a direct palette variable to avoid the 'layer' issue [cite: 75, 84]
                        color: Colours.palette.m3surfaceContainerLow
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: prerequisitesColumn
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.padding.large

                            StyledText {
                                text: qsTr("System Requirements")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3primary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Caelestia is lightweight, but performing well requires meeting these hardware minimums.")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                                opacity: 0.8
                            }
                            // Pill Container
                            Flow {
                                Layout.fillWidth: true
                                spacing: 10 // Flow uses 'spacing' for both directions; 'rowSpacing' isn't a thing here.

                                Repeater {
                                    model: [
                                        { label: "CPU", val: "x86_64 Dual Core" },
                                        { label: "RAM", val: "4GB" },
                                        { label: "Disk", val: "256GB" },
                                        { label: "GPU", val: "Modern iGPU(Iris Xe or Radeon)/Dedicated" },
                                        { label: "Display", val: "1366x768+"}
                                    ]

                                    delegate: StyledRect {
                                        width: pillRow.implicitWidth + 24
                                        height: 32
                                        radius: 16
                                        color: Colours.palette.m3surfaceContainerHigh
                                        border.color: Colours.palette.m3outlineVariant

                                        RowLayout {
                                            id: pillRow
                                            anchors.centerIn: parent
                                            spacing: 6
                                            StyledText {
                                                text: modelData.label + ":"
                                                font.bold: true
                                                font.pointSize: 10
                                                color: Colours.palette.m3primary
                                            }
                                            StyledText {
                                                text: modelData.val
                                                font.pointSize: 10
                                                color: Colours.palette.m3onSurface
                                            }
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredHeight: noteText.implicitHeight + 16
                                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                                radius: Appearance.rounding.small
                                Layout.topMargin: Appearance.padding.small

                                StyledText {
                                    id: noteText
                                    anchors.centerIn: parent
                                    width: parent.width - 24
                                    text: qsTr("Note: ARM processors (SnapDragon) are not officially supported.")
                                    font.pointSize: Appearance.font.size.small
                                    font.italic: true
                                    color: Colours.palette.m3error // Visual warning for compatibility
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        id: personalRequirementsSection
                        Layout.fillWidth: true
                        spacing: Appearance.padding.large

                        // Card 1: The Linux Philosophy
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.preferredHeight: philosophyColumn.implicitHeight + (Appearance.padding.large * 2)
                            color: Colours.palette.m3surfaceContainerLow
                            radius: Appearance.rounding.normal
                            border.color: Colours.palette.m3outlineVariant

                            ColumnLayout {
                                id: philosophyColumn
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.large
                                spacing: Appearance.padding.medium

                                StyledText {
                                    text: qsTr("The Linux Philosophy")
                                    font.bold: true
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3primary
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("This isn't Windows. Linux and by extension Caelestia is a totally different way of experiencing your PC—without limits, bloat, or spyware. Your machine belongs to you.")
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurface
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // Card 2: Learning Mindset
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.preferredHeight: learningColumn.implicitHeight + (Appearance.padding.large * 2)
                            color: Colours.palette.m3surfaceContainerLow
                            radius: Appearance.rounding.normal
                            border.color: Colours.palette.m3outlineVariant

                            ColumnLayout {
                                id: learningColumn
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.large
                                spacing: Appearance.padding.medium

                                RowLayout {
                                    spacing: 8
                                    // You could add an icon here later
                                    StyledText {
                                        text: qsTr("An Aptitude for Learning")
                                        font.bold: true
                                        font.pointSize: Appearance.font.size.normal
                                        color: Colours.palette.m3primary
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: qsTr("We expect you to learn and grow. While our community is here to help, Caelestia is about your unique journey. Never stop learning!")
                                    font.pointSize: Appearance.font.size.normal
                                    color: Colours.palette.m3onSurface
                                    wrapMode: Text.WordWrap
                                }

                                // Picasso Quote as a stylized footer
                                StyledText {
                                    Layout.fillWidth: true
                                    text: "I am always doing that which I cannot do, in order that I may learn how to do it. — Pablo Picasso"
                                    font.pointSize: Appearance.font.size.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    horizontalAlignment: Text.AlignRight
                                    wrapMode: Text.WordWrap
                                    opacity: 0.8
                                }
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


                    ColumnLayout {
                        id: firstStepsSection1
                        Layout.fillWidth: true
                        // REMOVE: Layout.minimumHeight: contentFlickable.height
                        Layout.leftMargin: Appearance.padding.larger
                        Layout.rightMargin: Appearance.padding.larger
                        Layout.topMargin: Appearance.padding.larger
                        spacing: Appearance.padding.large

                        ColumnLayout {
                            spacing: 4
                            StyledText {
                                text: "First Steps"
                                font.pointSize: Appearance.font.size.extraLarge
                                font.bold: true
                                color: Colours.palette.m3onBackground
                            }
                            StyledText {
                                text: "Master the Caelestia shell with these essential hotkeys."
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.preferredHeight: bindsGrid.implicitHeight + 60
                            color: Colours.palette.m3surfaceContainerLow
                            radius: Appearance.rounding.normal
                            border.color: Colours.palette.m3outlineVariant

                            GridLayout {
                                id: bindsGrid
                                anchors.fill: parent
                                anchors.margins: 30
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 20

                                // Helper for creating "Key" badges
                                Repeater {
                                    model: [
                                        { keys: "SUPER", desc: "Open App Launcher" },
                                        { keys: "SUPER + T", desc: "Terminal (Foot)" },
                                        { keys: "SUPER + E", desc: "File Explorer (Thunar)" },
                                        { keys: "SUPER + W", desc: "Web Browser (Zen)" },
                                        { keys: "SUPER + Q", desc: "Close Active Window" },
                                        { keys: "CTRL + SHIFT + ESC", desc: "System Monitor (Btop)" }
                                    ]
                                    delegate: RowLayout {
                                        spacing: 15
                                        Layout.fillWidth: true

                                        // The "Key" Badge
                                        StyledRect {
                                            width: keyText.implicitWidth + 20
                                            height: 32
                                            radius: 6
                                            color: Colours.palette.m3surfaceContainerHigh
                                            border.color: Colours.palette.m3outline

                                            StyledText {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: modelData.keys
                                                font.bold: true
                                                font.pointSize: 9
                                                color: Colours.palette.m3primary
                                            }
                                        }

                                        StyledText {
                                            text: modelData.desc
                                            font.pointSize: 10
                                            color: Colours.palette.m3onSurface
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        id: firstStepsSection2
                        Layout.fillWidth: true
                        // REMOVE: Layout.minimumHeight: contentFlickable.height
                        Layout.leftMargin: Appearance.padding.larger
                        Layout.rightMargin: Appearance.padding.larger
                        Layout.topMargin: Appearance.padding.larger
                        spacing: Appearance.padding.large

                        ColumnLayout {
                            spacing: 4
                            StyledText {
                                text: "Applications"
                                font.pointSize: Appearance.font.size.extraLarge
                                font.bold: true
                                color: Colours.palette.m3onBackground
                            }
                            StyledText {
                                text: "Lets take a look at your default applications."
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.preferredHeight: bindsGrid.implicitHeight + 60
                            color: Colours.palette.m3surfaceContainerLow
                            radius: Appearance.rounding.normal
                            border.color: Colours.palette.m3outlineVariant

                            GridLayout {
                                id: appsGrid
                                anchors.fill: parent
                                anchors.margins: 30
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 20

                                // Helper for creating "Key" badges
                                Repeater {
                                    model: [
                                        { keys: "Thunar", desc: "File Manager" },
                                        { keys: "Zen", desc: "Web Browser" },
                                        { keys: "Foot", desc: "Terminal" },
                                        { keys: "Arch-Update", desc: "Update Notifications" },
                                    ]
                                    delegate: RowLayout {
                                        spacing: 15
                                        Layout.fillWidth: true

                                        // The "Key" Badge
                                        StyledRect {
                                            width: keyText.implicitWidth + 20
                                            height: 32
                                            radius: 6
                                            color: Colours.palette.m3surfaceContainerHigh
                                            border.color: Colours.palette.m3outline

                                            StyledText {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: modelData.keys
                                                font.bold: true
                                                font.pointSize: 9
                                                color: Colours.palette.m3primary
                                            }
                                        }

                                        StyledText {
                                            text: modelData.desc
                                            font.pointSize: 10
                                            color: Colours.palette.m3onSurface
                                            Layout.fillWidth: true
                                        }
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
                    id: workspacesSection
                    Layout.fillWidth: true
                    Layout.margins: 40
                    spacing: Appearance.padding.large

                    // Header
                    ColumnLayout {
                        spacing: 4
                        StyledText {
                            text: "Workspaces"
                            font.pointSize: Appearance.font.size.extraLarge
                            font.bold: true
                            color: Colours.palette.m3onBackground
                        }
                        StyledText {
                            text: "Master the art of tiling and multitasking."
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Card 1: Normal Workspaces (1-10)
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: normalWorkCol.implicitHeight + 60
                        color: Colours.palette.m3surfaceContainerLow
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: normalWorkCol
                            anchors.fill: parent
                            anchors.margins: 30
                            spacing: 20

                            StyledText {
                                text: "Window Management"
                                font.bold: true
                                color: Colours.palette.m3primary
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 15
                                Layout.fillWidth: true

                                Repeater {
                                    model: [
                                        { keys: "SUPER + #", desc: "Switch to Workspace" },
                                        { keys: "SUPER + ALT + #", desc: "Move Window to Workspace" },
                                        { keys: "SUPER + ALT + Arrows", desc: "Move Window Directionally" },
                                        { keys: "SUPER + F", desc: "Toggle Fullscreen" }
                                    ]
                                    delegate: RowLayout {
                                        spacing: 12
                                        StyledRect {
                                            width: keyText.implicitWidth + 20
                                            height: 32
                                            radius: 6
                                            color: Colours.palette.m3surfaceContainerHigh
                                            border.color: Colours.palette.m3outline
                                            StyledText {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: modelData.keys
                                                font.bold: true; font.pointSize: 8
                                                color: Colours.palette.m3primary
                                            }
                                        }
                                        StyledText {
                                            text: modelData.desc
                                            font.pointSize: 10
                                            font.bold: true
                                            color: Colours.palette.m3onSurface
                                        }
                                    }
                                }
                            }
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: specialWorkCol.implicitHeight + 60
                        color: "transparent"
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outline

                        ColumnLayout {
                            id: specialWorkCol
                            anchors.fill: parent
                            anchors.margins: 30
                            spacing: 20

                            StyledText {
                                text: "Special Workspaces"
                                font.bold: true
                                color: Colours.palette.m3onSurface
                            }

                            GridLayout {
                                id: specialGrid
                                columns: 2
                                columnSpacing: 30
                                rowSpacing: 15
                                Layout.fillWidth: true

                                Repeater {
                                    model: [
                                        { key: "D", label: "Discord & WhatsApp", desc: "Communication hub" },
                                        { key: "M", label: "Music & Media", desc: "Spotify / MPD" },
                                        { key: "S", label: "Special Scratchpad", desc: "Floating terminal / Notes" },
                                        { key: "A", label: "ToDo Lists", desc: "Task management" }
                                    ]
                                    delegate: RowLayout {
                                        spacing: 15
                                        Layout.fillWidth: true
                                        StyledRect {
                                            width: 100
                                            height: 32
                                            radius: 6
                                            color: Colours.palette.m3surfaceContainerHigh
                                            border.color: Colours.palette.m3outline

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: "SUPER + " + modelData.key
                                                font.bold: true
                                                font.pointSize: 8
                                                color: Colours.palette.m3primary
                                            }
                                        }
                                        ColumnLayout {
                                            spacing: 2
                                            StyledText {
                                                text: modelData.label
                                                font.pointSize: 10
                                                font.bold: true
                                                color: Colours.palette.m3onSurface
                                            }
                                            StyledText {
                                                text: modelData.desc
                                                font.pointSize: 9
                                                color: Colours.palette.m3onSurfaceVariant
                                                opacity: 0.7
                                            }
                                        }
                                    }
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
