pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
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
            id: "before-you-begin",
            name: qsTr("Before You Begin"),
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

        ColumnLayout {
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

                // Before You Begin
                ColumnLayout {
                    id: beforeYouBeginSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.padding.large

                    WelcomeSectionHeader {
                        title: qsTr("Before You Begin")
                        subtitle: qsTr("Things to know before you start your journey.")
                    }

                    // System requirements
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: systemRequirements.implicitHeight + Appearance.padding.large * 2
                        color: Colours.palette.m3surfaceContainerLow
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: systemRequirements

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.larger

                            StyledText {
                                text: qsTr("System Requirements")
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: Colours.palette.m3primary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Caelestia is built on Hyprland and Quickshell. This combination is lightweight, but for best results, the following minimum requirements are advised.")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }

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
                                        height: Appearance.font.size.small + Appearance.padding.larger * 2
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

                    // The Linux Philosophy
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: linuxPhilosophy.implicitHeight + Appearance.padding.large * 2
                        color: Colours.palette.m3surfaceContainerLow
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: linuxPhilosophy

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.larger

                            StyledText {
                                text: qsTr("The Linux Philosophy")
                                font.bold: true
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3primary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Linux is an ecosystem built on the idea that \"small is beautiful\". Unlike other operating systems that rely on massive, all-in-one applications, Linux is a collection of specialized tools designed to do one thing and do it well. Linux gives you the power to combine these tools, building complex solutions from simple building blocks. It's a transparent, community driven world where you have total control over your machine.")
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurface
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // An Aptitude for Learning
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: aptitudeForLearning.implicitHeight + Appearance.padding.large * 2
                        color: Colours.palette.m3surfaceContainerLow
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: aptitudeForLearning

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.larger

                            StyledText {
                                text: qsTr("An Aptitude for Learning")
                                font.bold: true
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3primary
                            }

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

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Installation
                ColumnLayout {
                    id: installationSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.spacing.large

                    WelcomeSectionHeader {
                        title: qsTr("Installation")
                        subtitle: qsTr("Taking your computer from raw to riced!")
                    }

                    // Coming soon
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: installationColumn.implicitHeight + Appearance.padding.large * 2
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: installationColumn

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.larger

                            StyledText {
                                Layout.fillWidth: true
                                text: "Content coming soon"
                                font.pointSize: Appearance.font.size.normal
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // First Steps
                ColumnLayout {
                    id: firstStepsSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.spacing.large

                    WelcomeSectionHeader {
                        title: qsTr("First Steps")
                        subtitle: qsTr("Master the Caelestia shell with these essential hotkeys.")
                    }

                    // First Steps Keybindings
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: firstStepsKeybindings.implicitHeight + Appearance.padding.large * 2
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: firstStepsKeybindings

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.larger

                            StyledGridView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight

                                model: [
                                    {
                                        key: qsTr("Super"),
                                        label: qsTr("Open app launcher")
                                    },
                                    {
                                        key: qsTr("Super + T"),
                                        label: qsTr("Open default terminal (Foot)"),
                                    },
                                    {
                                        key: qsTr("Super + E"),
                                        label: qsTr("Open file explorer (Thunar)")
                                    },
                                    {
                                        key: qsTr("Super + W"),
                                        label: qsTr("Open web browser (Zen)")
                                    },
                                    {
                                        key: qsTr("Ctrl + Shift + Escape"),
                                        label: qsTr("Open system monitor (bTop)"),
                                    },
                                    {
                                        key: qsTr("Super + Q"),
                                        label: qsTr("Close active window")
                                    }
                                ]

                                spacing: 12
                                paddingX: 16

                                cellContent: Component {
                                    Item {
                                        id: firstStepsKeybindingWrapper

                                        property var modelData
                                        property real gridMeasureWidth: firstStepsKeybinding.implicitWidth

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.padding.small
                                            spacing: Appearance.spacing.small

                                            Keybinding {
                                                id: firstStepsKeybinding

                                                key: firstStepsKeybindingWrapper.modelData.key
                                                label: firstStepsKeybindingWrapper.modelData.label
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    WelcomeSectionHeader {
                        title: qsTr("Applications")
                        subtitle: qsTr("Learn about the default applications.")
                    }

                    // Default Applications
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: defaultApplications.implicitHeight + Appearance.padding.large * 2
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        RowLayout {
                            id: defaultApplications

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.large

                            ColumnLayout {
                                IconButton {
                                    icon: "chevron_left"
                                    onClicked: {
                                        if (defaultApplicationsCarousel.currentIndex === 0)
                                            defaultApplicationsCarousel.setCurrentIndex(defaultApplicationsCarousel.count - 1)
                                        else
                                            defaultApplicationsCarousel.setCurrentIndex(defaultApplicationsCarousel.currentIndex - 1)
                                    }
                                }
                            }

                            SwipeView {
                                id: defaultApplicationsCarousel

                                Layout.fillWidth: true
                                clip: true

                                Repeater {
                                    model: [
                                        {
                                            cat: qsTr("File Manager"),
                                            title: qsTr("Thunar"),
                                            icon: "../../assets/icons/thunar.svg",
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
                                            icon: "../../assets/icons/zen-browser.svg",
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
                                            icon: "../../assets/icons/discord.svg",
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
                                            icon: "../../assets/icons/foot.svg",
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
                                            icon: "../../assets/icons/spotify.svg",
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
                                            icon: "../../assets/icons/vscodium.svg",
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
                                            cat: qsTr("Software Updater"),
                                            title: qsTr("Arch Update"),
                                            icon: "../../assets/icons/arch-update.svg",
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
                                            icon: "../../assets/icons/btop.svg",
                                            desc: qsTr("Btop is a lightweight, CLI resource monitor and the successor to bpytop which shows usage and stats for your processor, memory, disks, network, and processes. It features full mouse support and a game-inspired interface."),
                                            links: [
                                                {
                                                    title: qsTr("GitHub"),
                                                    url: "https://github.com/aristocratos/btop"
                                                }
                                            ]
                                        },
                                    ]

                                    Page {
                                        id: defaultApplication

                                        required property var modelData

                                        RowLayout {
                                            id: defaultApplicationRow

                                            anchors.fill: parent
                                            Layout.margins: Appearance.padding.large

                                            spacing: Appearance.spacing.large

                                            VectorImage {
                                                id: defaultApplicationIcon

                                                Layout.preferredWidth: 64
                                                Layout.preferredHeight: 64
                                                Layout.alignment: Qt.AlignTop
                                                preferredRendererType: VectorImage.CurveRenderer
                                                fillMode: VectorImage.PreserveAspectFit
                                                source: defaultApplication.modelData.icon
                                            }

                                            ColumnLayout {
                                                id: defaultApplicationDesc

                                                Layout.fillWidth: true
                                                Layout.preferredWidth: parent.width
                                                Layout.alignment: Qt.AlignTop

                                                Text {
                                                    font.bold: true
                                                    font.pointSize: Appearance.font.size.larger
                                                    color: Colours.palette.m3onSurface
                                                    text: defaultApplication.modelData.cat + " - " + defaultApplication.modelData.title
                                                }

                                                Text {
                                                    Layout.preferredWidth: parent.width
                                                    font.pointSize: Appearance.font.size.normal
                                                    color: Colours.palette.m3onSurface
                                                    wrapMode: Text.WordWrap
                                                    text: defaultApplication.modelData.desc
                                                }

                                                RowLayout {
                                                    Layout.topMargin: Appearance.padding.normal

                                                    spacing: Appearance.spacing.normal
                                                    visible: defaultApplication.modelData.links

                                                    Repeater {
                                                        model: defaultApplication.modelData.links

                                                        TextButton {
                                                            id: defaultApplicationLink

                                                            required property var modelData

                                                            text: defaultApplicationLink.modelData.title
                                                            radius: Appearance.rounding.small

                                                            onClicked: Qt.openUrlExternally(defaultApplicationLink.modelData.url)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                IconButton {
                                    icon: "chevron_right"
                                    onClicked: {
                                        if (defaultApplicationsCarousel.currentIndex === defaultApplicationsCarousel.count - 1)
                                            defaultApplicationsCarousel.setCurrentIndex(0)
                                        else
                                            defaultApplicationsCarousel.setCurrentIndex(defaultApplicationsCarousel.currentIndex + 1)
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Workspaces
                ColumnLayout {
                    id: workspacesSection

                    Layout.fillWidth: true
                    Layout.minimumHeight: contentFlickable.height
                    Layout.leftMargin: Appearance.padding.larger
                    Layout.rightMargin: Appearance.padding.larger
                    spacing: Appearance.spacing.large

                    WelcomeSectionHeader {
                        title: qsTr("Workspaces")
                        subtitle: qsTr("Master the art of tiling and multitasking.")
                    }

                    // Standard Workspaces
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: standardWorkspaces.implicitHeight + Appearance.padding.large * 2
                        color: Colours.palette.m3surfaceContainerLow
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: standardWorkspaces

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.large

                            StyledGridView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight

                                model: [
                                    {
                                        key: qsTr("Super + <#>"),
                                        label: qsTr("Switch to workspace")
                                    },
                                    {
                                        key: qsTr("Super + Alt + <#>"),
                                        label: qsTr("Move window to workspace"),
                                    },
                                    {
                                        key: qsTr("Super + Alt + <Up|Down|Left|Right>"),
                                        label: qsTr("Move window directionally")
                                    },
                                    {
                                        key: qsTr("Super + F"),
                                        label: qsTr("Toggle fullscreen")
                                    }
                                ]

                                spacing: 12
                                paddingX: 16

                                cellContent: Component {
                                    Item {
                                        property var modelData
                                        property real gridMeasureWidth: firstStepsKeybinding.implicitWidth

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.padding.small
                                            spacing: Appearance.spacing.small

                                            Keybinding {
                                                id: firstStepsKeybinding

                                                key: modelData.key
                                                label: modelData.label
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    WelcomeSectionHeader {
                        title: qsTr("Special Workspaces")
                        subtitle: qsTr("Keep important things close, but out of the way.")
                    }

                    // Standard Workspaces
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: specialWorkspaces.implicitHeight + Appearance.padding.large * 2
                        color: Colours.palette.m3surfaceContainerLow
                        radius: Appearance.rounding.normal
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: specialWorkspaces

                            anchors.fill: parent
                            anchors.margins: Appearance.padding.large
                            spacing: Appearance.spacing.large

                            StyledGridView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight

                                model: [
                                    {
                                        key: qsTr("Super + D"),
                                        label: qsTr("Communications Hub"),
                                        desc: qsTr("Discord")
                                    },
                                    {
                                        key: qsTr("Super + M"),
                                        label: qsTr("Music & Media"),
                                        desc: qsTr("Spotify")
                                    },
                                    {
                                        key: qsTr("Super + A"),
                                        label: qsTr("ToDo List"),
                                        desc: qsTr("Todoist")
                                    },
                                    {
                                        key: qsTr("Super + S"),
                                        label: qsTr("Special"),
                                        desc: qsTr("Scratchpad Workspace")
                                    }
                                ]

                                spacing: 12
                                paddingX: 16

                                cellContent: Component {
                                    Item {
                                        id: specialWorkspacesItem

                                        required property var modelData
                                        property real gridMeasureWidth: specialWorkspacesKeybinding.implicitWidth

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.padding.small
                                            spacing: Appearance.spacing.small

                                            Keybinding {
                                                id: specialWorkspacesKeybinding

                                                key: specialWorkspacesItem.modelData.key
                                                label: specialWorkspacesItem.modelData.label
                                                desc: specialWorkspacesItem.modelData.desc
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
