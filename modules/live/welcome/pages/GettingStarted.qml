pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components
import qs.components.live
import qs.config

ScrollablePage {
    id: root

    readonly property string shellDir: Quickshell.shellDir

    // Before You Begin
    PageSection {
        id: beforeYouBeginSection

        sectionId: "beforeYouBegin"
        sectionName: qsTr("Before You Begin")
        sectionIcon: "checklist"

        sectionHeader.title: qsTr("Before You Begin")
        sectionHeader.subtitle: qsTr("Things to know before you start your journey.")

        SectionContentArea {
            title: qsTr("System Requirements")
            subtitle: qsTr("Caelestia is built on Hyprland and Quickshell. This combination is lightweight, but for best results, the following minimum requirements are advised.")

            content: Component {
                ColumnLayout {
                    Layout.fillWidth: true

                    Flow {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller

                        Repeater {
                            model: [
                                {
                                    label: qsTr("CPU"),
                                    val: qsTr("x86_64 Dual Core")
                                },
                                {
                                    label: qsTr("RAM"),
                                    val: qsTr("4GB")
                                },
                                {
                                    label: qsTr("Disk"),
                                    val: qsTr("256GB")
                                },
                                {
                                    label: qsTr("GPU"),
                                    val: qsTr("Modern iGPU (Iris Xe or Radeon) or better")
                                },
                                {
                                    label: qsTr("Display"),
                                    val: qsTr("1366x768 or higher")
                                }
                            ]

                            delegate: StyledRect {
                                id: requirementsWrapper

                                required property var modelData

                                width: requirements.implicitWidth + Appearance.padding.larger * 2
                                height: requirements.implicitHeight + Appearance.padding.larger * 2
                                radius: Appearance.rounding.normal
                                color: Colours.palette.m3surfaceContainerHigh
                                border.color: Colours.palette.m3outlineVariant

                                RowLayout {
                                    id: requirements

                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.small

                                    StyledText {
                                        text: requirementsWrapper.modelData.label + ":"
                                        font.bold: true
                                        font.pointSize: Appearance.font.size.small
                                        color: Colours.palette.m3primary
                                    }

                                    StyledText {
                                        text: requirementsWrapper.modelData.val
                                        font.pointSize: Appearance.font.size.small
                                        color: Colours.palette.m3onSurface
                                    }
                                }
                            }
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: requirementsNote.implicitHeight + Appearance.padding.larger * 2
                        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                        radius: Appearance.rounding.small
                        Layout.topMargin: Appearance.padding.small

                        StyledText {
                            id: requirementsNote

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
        }

        SectionContentArea {
            title: qsTr("The Linux Philosophy")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Linux is an ecosystem built on the idea that \"small is beautiful\". Unlike other operating systems that rely on massive, all-in-one applications, Linux is a collection of specialized tools designed to do one thing and do it well. Linux gives you the power to combine these tools, building complex solutions from simple building blocks. It's a transparent, community driven world where you have total control over your machine.")
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        SectionContentArea {
            title: qsTr("An Aptitude for Learning")

            Layout.topMargin: Appearance.padding.large

            content: Component {
                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("While our community is here to help, Caelestia is about your personal journey. Everyone has their own unique needs and tastes, and every install of Caelestia is tailored to its user. We do our best to support our users, but it's always possible that you'll come up with a question we don't have an immediate answer to. Our hope is that you continually learn and eventually share your knowledge with the community, improving the community as a whole in the process.")
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("\"I am always doing that which I cannot do, in order that I may learn how to do it.\" — Pablo Picasso")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                    }
                }
            }
        }
    }

    // Installation
    PageSection {
        id: installationSection

        sectionId: "installation"
        sectionName: qsTr("Installation")
        sectionIcon: "download"

        sectionHeader.title: qsTr("Installation")
        sectionHeader.subtitle: qsTr("Taking your computer from raw to riced!")

        SectionContentArea {
            title: qsTr("Installing Caelestia")

            content: Component {
                ColumnLayout {
                    StyledText {
                        Layout.fillWidth: true
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        text: qsTr("Content coming soon.")
                    }
                }
            }
        }
    }

    // First Steps
    PageSection {
        id: firstStepsSection

        sectionId: "firstSteps"
        sectionName: qsTr("First Steps")
        sectionIcon: "bolt"

        sectionHeader.title: qsTr("First Steps")
        sectionHeader.subtitle: qsTr("Master the Caelestia shell with these essential hotkeys.")

        ColumnLayout {
            SectionContentArea {
                content: Component {
                    ColumnLayout {
                        spacing: Appearance.spacing.normal

                        KeybindingRow {
                            keys: [qsTr("Super")]
                            label: qsTr("Open app launcher")
                        }

                        KeybindingRow {
                            keys: [qsTr("Super"), "T"]
                            label: qsTr("Open default terminal")
                            desc: qsTr("Foot")
                        }

                        KeybindingRow {
                            keys: [qsTr("Super"), "E"]
                            label: qsTr("Open file explorer")
                            desc: qsTr("Thunar")
                        }

                        KeybindingRow {
                            keys: [qsTr("Super"), "W"]
                            label: qsTr("Open web browser")
                            desc: qsTr("Zen")
                        }

                        KeybindingRow {
                            keys: [qsTr("Ctrl"), qsTr("Shift"), qsTr("Escape")]
                            label: qsTr("Open system monitor")
                            desc: qsTr("btop")
                        }

                        KeybindingRow {
                            keys: [qsTr("Super"), "Q"]
                            label: qsTr("Close active window")
                        }
                    }
                }
            }

            SectionHeader {
                title: qsTr("Applications")
                subtitle: qsTr("CaelestiaLive includes a number of default applications to help you get started on your journey.")
                fontSize: Appearance.font.size.large
                Layout.topMargin: Appearance.padding.large
            }

            // Default Applications
            SectionContentArea {
                Layout.topMargin: Appearance.padding.large

                content: Component {
                    ColumnLayout {
                        ApplicationCarousel {
                            sourceModel: [
                                {
                                    cat: qsTr("File Manager"),
                                    title: qsTr("Thunar"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/thunar.svg`),
                                    desc: qsTr("Thunar is a clean, modern file manager originally developed for Xfce. It is designed for speed and efficiency, and features a familiar, intuitive interface. Despite its simplicity, Thunar is extensible through plugins."),
                                    links: [
                                        {
                                            title: qsTr("Arch Wiki"),
                                            url: "https://wiki.archlinux.org/title/Thunar"
                                        },
                                        {
                                            title: qsTr("Website"),
                                            url: "https://docs.xfce.org/xfce/thunar/start"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Web Browser"),
                                    title: qsTr("Zen"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/zen-browser.svg`),
                                    desc: qsTr("Zen is an experimental, performance-optimized fork of Firefox focused on flexibility and design with many new features added to the core Firefox feature set. It also removes the Firefox AI components and tracking."),
                                    links: [
                                        {
                                            title: qsTr("Website"),
                                            url: "https://www.zen-browser.app/"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Chat"),
                                    title: qsTr("Discord"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/discord.svg`),
                                    desc: qsTr("Discord is a cross-platform voice and text chat application which can be used through a web browser or the official desktop application. Many open-source communities (including ours) have communities on Discord."),
                                    links: [
                                        {
                                            title: qsTr("Arch Wiki"),
                                            url: "https://wiki.archlinux.org/title/Discord"
                                        },
                                        {
                                            title: qsTr("Website"),
                                            url: "https://discord.com"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Terminal"),
                                    title: qsTr("Foot"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/foot.svg`),
                                    desc: qsTr("Foot is a fast, lightweight terminal emulator specifically designed for use under Wayland. It supports features such as server/daemon mode, scrollback search, URL detection, color emojis, and true color."),
                                    links: [
                                        {
                                            title: qsTr("Arch Wiki"),
                                            url: "https://wiki.archlinux.org/title/Foot"
                                        },
                                        {
                                            title: qsTr("Codeberg"),
                                            url: "https://codeberg.org/dnkl/foot"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Music Player"),
                                    title: qsTr("Spotify"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/spotify.svg`),
                                    desc: qsTr("Spotify is a digital music streaming service which supports both an online player through their website, and a semi-official Linux client. Spotify operates on a freemium business model."),
                                    links: [
                                        {
                                            title: qsTr("Arch Wiki"),
                                            url: "https://wiki.archlinux.org/title/Spotify"
                                        },
                                        {
                                            title: qsTr("Website"),
                                            url: "https://spotify.com"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Code Editor"),
                                    title: qsTr("VSCodium"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/vscodium.svg`),
                                    desc: qsTr("VSCodium is a community-driven open-source text and code editor based on Visual Studio Code. It removes telemetry from VSCode and ships configuration with Open VSX."),
                                    links: [
                                        {
                                            title: qsTr("Arch Wiki"),
                                            url: "https://wiki.archlinux.org/title/Visual_Studio_Code"
                                        },
                                        {
                                            title: qsTr("Website"),
                                            url: "https://vscodium.com/"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Office Suite"),
                                    title: qsTr("LibreOffice"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/libreoffice.svg`),
                                    desc: qsTr("LibreOffice is a powerful, flexible office suite that is compatible with Microsoft Office (365) and is backed by the non-profit The Document Foundation. The LibreOffice suite consists of Writer (word processing), Calc (spreadsheets), Impress (presentations), Draw (vector graphics and flowcharts), Base (databases), and Math (formula editing)."),
                                    links: [
                                        {
                                            title: qsTr("Arch Wiki"),
                                            url: "https://wiki.archlinux.org/title/LibreOffice"
                                        },
                                        {
                                            title: qsTr("Website"),
                                            url: "https://www.libreoffice.org/"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Productivity"),
                                    title: qsTr("Todoist"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/todoist.svg`),
                                    desc: qsTr("Todoist is a cross-platform task management tool that helps you organize your personal and professional tasks in a simple and efficient way. It allows creation of todo lists and reminders, and tracks your productivity across various devices."),
                                    links: [
                                        {
                                            title: qsTr("Website"),
                                            url: "https://www.todoist.com/"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Software Updater"),
                                    title: qsTr("Arch Update"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/arch-update.svg`),
                                    desc: qsTr("Arch Update is an interactive update notifier and updater for Arch Linux that assists you with important pre- and post-update tasks. It runs on a timer, and provides a systray icon to make your life even easier."),
                                    links: [
                                        {
                                            title: qsTr("GitHub"),
                                            url: "https://github.com/Antiz96/arch-update"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("System Monitor"),
                                    title: qsTr("bTop"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/btop.svg`),
                                    desc: qsTr("Btop is a lightweight, CLI resource monitor and the successor to bpytop which shows usage and stats for your processor, memory, disks, network, and processes. It features full mouse support and a game-inspired interface."),
                                    links: [
                                        {
                                            title: qsTr("GitHub"),
                                            url: "https://github.com/aristocratos/btop"
                                        }
                                    ]
                                },
                                {
                                    cat: qsTr("Arch Powered"),
                                    title: qsTr("The options are endless!"),
                                    icon: Qt.resolvedUrl(`${root.shellDir}/modules/live/assets/icons/archlinux.svg`),
                                    desc: qsTr("CaelestiaLive is built on ArchLinux, and users have access to all of the applications included in both the official Arch repositories and the AUR. We bundle yay by default for package management, but you're free to switch to paru or whatever other package manager you want!"),
                                    links: [
                                        {
                                            title: qsTr("Arch Packages"),
                                            url: "https://archlinux.org/packages/"
                                        },
                                        {
                                            title: qsTr("Arch User Repository"),
                                            url: "https://aur.archlinux.org"
                                        }
                                    ]
                                }
                            ]
                        }
                    }
                }
            }
        }
    }
}
