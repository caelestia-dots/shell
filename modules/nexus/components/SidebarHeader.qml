pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property NexusSession session

    readonly property bool collapsed: session.sidebarCollapsed

    property bool searchDropdownOpen: false
    property bool configDropdownOpen: false

    // Build config model: Global + monitors
    readonly property var configModel: {
        const items = [
            {
                id: "global",
                label: "Global",
                icon: "language",
                desc: "Settings apply everywhere"
            }
        ];
        for (const screen of Screens.screens) {
            items.push({
                id: screen.name,
                label: screen.name,
                icon: "monitor",
                desc: "Monitor-specific overrides"
            });
        }
        return items;
    }

    implicitHeight: headerLayout.implicitHeight

    ColumnLayout {
        id: headerLayout

        anchors.fill: parent
        spacing: 0

        // Search bar
        Item {
            id: searchItem

            Layout.fillWidth: true
            Layout.preferredHeight: root.collapsed ? 64 : 44

            Behavior on Layout.preferredHeight {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }

            StyledRect {
                id: searchBtn

                anchors.fill: parent

                radius: root.collapsed ? Tokens.rounding.normal : Tokens.rounding.full
                color: {
                    if (root.session.searchPopoutOpen && root.collapsed)
                        return Qt.alpha(Colours.palette.m3secondaryContainer, 0.16);
                    if (!root.collapsed)
                        return Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.6);
                    return "transparent";
                }

                Behavior on radius {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
                Behavior on color {
                    CAnim {}
                }

                // Collapsed mode: click to open popout
                StateLayer {
                    visible: root.collapsed
                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                    onClicked: {
                        root.session.searchPopoutOpen = !root.session.searchPopoutOpen;
                        root.session.configPopoutOpen = false;
                    }
                }

                MaterialIcon {
                    id: searchIcon

                    x: root.collapsed ? (parent.width - width) / 2 : Tokens.padding.large
                    y: root.collapsed ? (parent.height - height) / 2 - 8 : (parent.height - height) / 2

                    text: "search"
                    font.pointSize: root.collapsed ? Tokens.font.size.large : Tokens.font.size.larger
                    color: {
                        if (root.session.searchPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, root.collapsed ? 0.5 : 0.4);
                    }

                    Behavior on x {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                    Behavior on font.pointSize {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Collapsed label
                StyledText {
                    visible: root.collapsed
                    x: (parent.width - width) / 2
                    y: parent.height - height - 6

                    text: "Search"
                    font.pointSize: Tokens.font.size.small - 1
                    color: {
                        if (root.session.searchPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.7);
                    }

                    opacity: root.collapsed ? 0.8 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Expanded mode: text input
                TextField {
                    id: searchField

                    visible: !root.collapsed
                    anchors.left: searchIcon.right
                    anchors.leftMargin: Tokens.spacing.normal
                    anchors.right: parent.right
                    anchors.rightMargin: searchClear.visible ? searchClear.width + Tokens.spacing.normal : Tokens.padding.large
                    anchors.verticalCenter: parent.verticalCenter

                    placeholderText: "Search settings..."
                    font.pointSize: Tokens.font.size.normal
                    color: Colours.palette.m3onSurface
                    placeholderTextColor: Qt.alpha(Colours.palette.m3onSurface, 0.3)
                    background: Item {}

                    onTextChanged: {
                        root.session.searchQuery = text;
                        root.searchDropdownOpen = text.length > 0;
                    }
                    onActiveFocusChanged: {
                        if (activeFocus && text.length > 0)
                            root.searchDropdownOpen = true;
                        else if (!activeFocus)
                            root.searchDropdownOpen = false;
                    }

                    Connections {
                        function onSidebarCollapsedChanged() {
                            if (root.session.sidebarCollapsed) {
                                searchField.focus = false;
                                root.searchDropdownOpen = false;
                            }
                        }

                        target: root.session
                    }
                }

                // Clear button (expanded)
                MaterialIcon {
                    id: searchClear

                    visible: !root.collapsed && root.session.searchQuery.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.padding.normal
                    anchors.verticalCenter: parent.verticalCenter

                    text: "close"
                    font.pointSize: Tokens.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)

                    StateLayer {
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3onSurface
                        onClicked: {
                            searchField.text = "";
                            root.session.searchQuery = "";
                            root.searchDropdownOpen = false;
                        }
                    }
                }
            }
        }

        Item {
            id: configItem

            Layout.fillWidth: true
            Layout.preferredHeight: root.collapsed ? 64 : 40
            Layout.topMargin: root.collapsed ? 4 : 8

            Behavior on Layout.preferredHeight {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }

            StyledRect {
                id: configBtn

                anchors.fill: parent
                radius: root.collapsed ? Tokens.rounding.normal : Tokens.rounding.full
                color: {
                    if (root.session.configPopoutOpen && root.collapsed)
                        return Qt.alpha(Colours.palette.m3secondaryContainer, 0.16);
                    if (root.configDropdownOpen && !root.collapsed)
                        return Qt.alpha(Colours.palette.m3secondaryContainer, 0.12);
                    if (!root.collapsed)
                        return Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.6);
                    return "transparent";
                }

                Behavior on radius {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
                Behavior on color {
                    CAnim {}
                }

                StateLayer {
                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                    onClicked: {
                        if (root.collapsed) {
                            root.session.configPopoutOpen = !root.session.configPopoutOpen;
                            root.session.searchPopoutOpen = false;
                        } else {
                            root.configDropdownOpen = !root.configDropdownOpen;
                            root.searchDropdownOpen = false;
                        }
                    }
                }

                MaterialIcon {
                    id: configIcon

                    x: root.collapsed ? (parent.width - width) / 2 : Tokens.padding.large
                    y: root.collapsed ? (parent.height - height) / 2 - 8 : (parent.height - height) / 2

                    text: root.session.activeConfig === "global" ? "language" : "monitor"
                    font.pointSize: root.collapsed ? Tokens.font.size.large : Tokens.font.size.larger
                    color: {
                        if (root.session.configPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        if (root.configDropdownOpen && !root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.5);
                    }

                    Behavior on x {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                    Behavior on font.pointSize {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Collapsed label
                StyledText {
                    visible: root.collapsed
                    x: (parent.width - width) / 2
                    y: parent.height - height - 6

                    text: root.session.activeConfig === "global" ? "Global" : root.session.activeConfig
                    font.pointSize: Tokens.font.size.small - 1
                    font.weight: Font.Medium
                    color: {
                        if (root.session.configPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.7);
                    }

                    opacity: root.collapsed ? 0.8 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Expanded label
                StyledText {
                    visible: !root.collapsed
                    anchors.left: configIcon.right
                    anchors.leftMargin: Tokens.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.session.activeConfig === "global" ? "Global" : root.session.activeConfig
                    font.pointSize: Tokens.font.size.normal
                    font.weight: Font.Medium
                    color: {
                        if (root.configDropdownOpen)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.6);
                    }

                    Behavior on color {
                        CAnim {}
                    }
                }

                MaterialIcon {
                    id: configChevron

                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.padding.large
                    anchors.verticalCenter: parent.verticalCenter

                    text: "expand_more"
                    font.pointSize: Tokens.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.4)
                    rotation: (root.session.configPopoutOpen && root.collapsed) || (root.configDropdownOpen && !root.collapsed) ? 180 : 0
                    opacity: root.collapsed ? 0 : 1

                    Behavior on rotation {
                        Anim {
                            type: Anim.StandardSmall
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.StandardSmall
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: Tokens.padding.normal
            Layout.rightMargin: Tokens.padding.normal
            Layout.topMargin: root.collapsed ? 8 : Tokens.spacing.normal
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
        }
    }

    // Search results dropdown (expanded)
    Rectangle {
        id: searchDropdown

        z: 10
        x: 0
        y: searchItem.y + searchItem.height + 4
        width: root.width
        height: root.searchDropdownOpen && !root.collapsed ? searchResultsCol.implicitHeight + Tokens.padding.normal * 2 : 0
        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainerHigh
        clip: true
        visible: height > 0

        Behavior on height {
            Anim {
                type: Anim.Emphasized
            }
        }

        Column {
            id: searchResultsCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.normal
            spacing: 2

            Repeater {
                model: root.session.searchQuery.length > 0 ? NexusRegistry.searchSettings(root.session.searchQuery) : [] // qmllint disable missing-property

                delegate: Item {
                    id: searchResultDelegate

                    required property var modelData

                    width: searchResultsCol.width
                    height: 44

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.spacing.normal
                        anchors.rightMargin: Tokens.spacing.normal
                        spacing: Tokens.spacing.normal

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 5
                            color: Qt.alpha(Colours.palette.m3primary, 0.1)

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "arrow_forward"
                                font.pointSize: Tokens.font.size.small - 1
                                color: Colours.palette.m3primary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - parent.spacing - 32

                            StyledText {
                                text: searchResultDelegate.modelData.label
                                font.pointSize: Tokens.font.size.normal
                                font.weight: Font.Medium
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: searchResultDelegate.modelData.categoryLabel + (searchResultDelegate.modelData.tab ? " › " + searchResultDelegate.modelData.tab : "")
                                font.pointSize: Tokens.font.size.small - 1
                                color: Qt.alpha(Colours.palette.m3onSurface, 0.4)
                            }
                        }
                    }

                    StateLayer {
                        radius: Tokens.rounding.small
                        color: Colours.palette.m3onSurface
                        onClicked: {
                            searchField.text = "";
                            root.session.searchQuery = "";
                            root.session.setSearchNavigate(searchResultDelegate.modelData.categoryId, searchResultDelegate.modelData.tab || "");
                            root.searchDropdownOpen = false;
                        }
                    }
                }
            }
        }
    }

    // Config dropdown (expanded)
    Rectangle {
        id: configDropdown

        z: 10
        x: 0
        y: configItem.y + configItem.height + 4
        width: root.width
        height: root.configDropdownOpen && !root.collapsed ? configDropdownCol.implicitHeight + Tokens.padding.normal * 2 : 0
        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainerHigh
        clip: true
        visible: height > 0

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        Column {
            id: configDropdownCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.normal
            spacing: 2

            Repeater {
                model: root.configModel

                delegate: Item {
                    id: configDropdownDelegate

                    required property var modelData
                    readonly property bool isActive: root.session.activeConfig === modelData.id

                    width: configDropdownCol.width
                    height: 44

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.spacing.normal
                        anchors.rightMargin: Tokens.spacing.normal
                        spacing: Tokens.spacing.normal

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: configDropdownDelegate.modelData.icon
                            font.pointSize: Tokens.font.size.normal
                            color: configDropdownDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - parent.spacing - 24

                            StyledText {
                                text: configDropdownDelegate.modelData.label
                                font.pointSize: Tokens.font.size.normal
                                font.weight: Font.Medium
                                color: configDropdownDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: configDropdownDelegate.modelData.desc
                                font.pointSize: Tokens.font.size.small - 1
                                color: Qt.alpha(Colours.palette.m3onSurface, 0.4)
                            }
                        }
                    }

                    StateLayer {
                        radius: Tokens.rounding.small
                        color: Colours.palette.m3onSurface
                        onClicked: {
                            root.session.activeConfig = configDropdownDelegate.modelData.id;
                            root.configDropdownOpen = false;
                        }
                    }
                }
            }
        }
    }
}
