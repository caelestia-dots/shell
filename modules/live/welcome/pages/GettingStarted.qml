import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.modules.live.components
import qs.components.containers
import qs.config
import "../../components"

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
                            
            Flow {
                Layout.fillWidth: true
                spacing: 10 
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
                    color: Colours.palette.m3error 
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
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("I am always doing that which I cannot do, in order that I may learn how to do it. — Pablo Picasso")
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
                            Layout.preferredHeight: bindsGrid.implicitHeight + 115
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

                                Repeater {
                                    model: [
                                        { keys: "Thunar", desc: "File Manager" },
                                        { keys: "Zen", desc: "Web Browser" },
                                        { keys: "Foot", desc: "Terminal" },
                                        { keys: "Arch-Update", desc: "Update Notifications" },
                                        { keys: "Btop", desc: "System Monitor" },
                                        { keys: "Discord", desc: "Communication Hub" },
                                        { keys: "Spotify", desc: "Music Player"},
                                        { keys: "Code -OSS", desc: "Code Editor"}
                                    ]
                                    delegate: RowLayout {
                                        spacing: 15
                                        Layout.fillWidth: true

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
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    Layout.topMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

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
                                text: "Window Management in standard workspaces"
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
                    StyledText {
                            text: "Special Workspaces"
                            font.pointSize: Appearance.font.size.extraLarge
                            font.bold: true
                            color: Colours.palette.m3onBackground
                        }
                        StyledText {
                            text: "Keeps Important things close and out of the way!"
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
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
                                text: "Access Special Workspaces"
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
                                        //{ key: "Ctrl + Shift + Esc", Label: "System Monitor", desc: "Btop" }
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
