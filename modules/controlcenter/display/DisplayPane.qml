pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    anchors.fill: parent

    Component {
        id: menuItemComponent
        MenuItem {}
    }

    SplitPaneLayout {
        id: splitLayout
        anchors.fill: parent

        leftContent: Component {
            StyledFlickable {
                id: leftFlickable
                flickableDirection: Flickable.VerticalFlick
                contentHeight: leftColumn.height

                StyledScrollBar.vertical: StyledScrollBar { flickable: leftFlickable }

                ColumnLayout {
                    id: leftColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal
                    anchors.margins: Appearance.padding.normal

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.smaller

                        StyledText {
                            text: qsTr("Display Configuration")
                            font.pointSize: Appearance.font.size.large
                            font.weight: 600
                            color: Colours.palette.m3onSurface
                        }
                    }

                    SettingsHeader { 
                        title: qsTr("Monitor Layout")
                        icon: "monitor"
                    }

                    // Modern Monitor Map
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 220
                        radius: Appearance.rounding.normal
                        color: Colours.tPalette.m3surfaceContainer

                        // Subtle grid effect
                        Item {
                            anchors.fill: parent
                            opacity: 0.05
                            Repeater {
                                model: Math.ceil(parent.width / 40)
                                Rectangle {
                                    x: index * 40; y: 0; width: 1; height: parent.height; color: Colours.palette.m3onSurface
                                }
                            }
                            Repeater {
                                model: Math.ceil(parent.height / 40)
                                Rectangle {
                                    x: 0; y: index * 40; width: parent.width; height: 1; color: Colours.palette.m3onSurface
                                }
                            }
                        }

                        Item {
                            id: mapArea
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.extraLarge

                            Repeater {
                                model: Display.monitors
                                delegate: StyledRect {
                                    id: monitorInstance
                                    required property var modelData
                                    
                                    readonly property real mapW: mapArea.width > 0 ? mapArea.width : 400
                                    readonly property real mapH: mapArea.height > 0 ? mapArea.height : 200
                                    readonly property real scaleFactor: Math.min(mapW / 3840, mapH / 2160) * 0.8
                                    
                                    x: (mapArea.width / 2) + (modelData.x * scaleFactor)
                                    y: (mapArea.height / 2) + (modelData.y * scaleFactor)
                                    width: Math.max(80, modelData.width * scaleFactor)
                                    height: Math.max(45, modelData.height * scaleFactor)
                                    
                                    radius: Appearance.rounding.small
                                    color: Display.selectedMonitor === modelData ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
                                    border.width: Display.selectedMonitor === modelData ? 2 : 1
                                    border.color: Display.selectedMonitor === modelData ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        MaterialIcon {
                                            text: modelData.name.startsWith("eDP") ? "laptop" : "monitor"
                                            color: Display.selectedMonitor === modelData ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            font.pointSize: 14
                                            Layout.alignment: Qt.AlignCenter
                                        }
                                        StyledText {
                                            text: index + 1
                                            color: Display.selectedMonitor === modelData ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            font.pointSize: Appearance.font.size.small
                                            font.weight: 700
                                            Layout.alignment: Qt.AlignCenter
                                        }
                                    }

                                    StateLayer {
                                        onClicked: Display.selectedMonitor = modelData
                                    }

                                    // Identifier tag
                                    StyledRect {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.margins: 4
                                        width: 18; height: 18; radius: 9
                                        color: Colours.palette.m3primary
                                        visible: Display.selectedMonitor === modelData
                                        StyledText {
                                            anchors.centerIn: parent
                                            text: index + 1
                                            font.pointSize: 8; font.weight: 800
                                            color: Colours.palette.m3onPrimary
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal
                        
                        IconTextButton {
                            text: qsTr("Identify")
                            icon: "visibility"
                            onClicked: {
                                if (Display.selectedMonitor) {
                                    Display.identify(Display.selectedMonitor.name);
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }

                    SettingsHeader { 
                        title: qsTr("Display Mode")
                        icon: "tune"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        Repeater {
                            model: [
                                { label: "Mirror", icon: "content_copy", mode: Display.DisplayMode.Mirror },
                                { label: "Extend", icon: "cast", mode: Display.DisplayMode.Extend },
                                { label: "Second", icon: "monitor", mode: Display.DisplayMode.ExternalOnly }
                            ]

                            delegate: StyledRect {
                                id: modeItem
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 70
                                radius: Appearance.rounding.normal
                                color: Colours.tPalette.m3surfaceContainerHigh

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.smaller
                                    MaterialIcon {
                                        text: modelData.icon
                                        color: Colours.palette.m3onSurface
                                        font.pointSize: Appearance.font.size.large
                                        Layout.alignment: Qt.AlignCenter
                                    }
                                    StyledText {
                                        text: modelData.label
                                        color: Colours.palette.m3onSurface
                                        font.pointSize: Appearance.font.size.small
                                        Layout.alignment: Qt.AlignCenter
                                    }
                                }

                                StateLayer {
                                    onClicked: Display.setMode(modelData.mode)
                                }
                            }
                        }
                    }
                }
            }
        }

        rightContent: Component {
            StyledFlickable {
                id: rightFlickable
                flickableDirection: Flickable.VerticalFlick
                contentHeight: rightColumn.height

                StyledScrollBar.vertical: StyledScrollBar { flickable: rightFlickable }

                ColumnLayout {
                    id: rightColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.large

                    SettingsHeader {
                        title: Display.selectedMonitor ? (Display.selectedMonitor.description || Display.selectedMonitor.name || qsTr("Monitor Settings")) : qsTr("Monitor Settings")
                        icon: "info"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !!Display.selectedMonitor
                        spacing: Appearance.spacing.large

                        // Resolution Section
                        SectionContainer {
                            SectionHeader { 
                                title: qsTr("Resolution & Refresh")
                                RowLayout {
                                    IconTextButton {
                                        icon: "restart_alt"
                                        text: qsTr("Reset to Default")
                                        onClicked: if (Display.selectedMonitor) Display.resetToPreferred(Display.selectedMonitor.name)
                                    }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.normal

                                ColumnLayout {
                                    spacing: Appearance.spacing.extraSmall
                                    StyledText { text: qsTr("Resolution"); opacity: 0.7; font.pointSize: Appearance.font.size.small }
                                    StyledRect {
                                        id: resButton
                                        Layout.fillWidth: true
                                        implicitHeight: 45
                                        radius: Appearance.rounding.small
                                        color: Colours.tPalette.m3surfaceContainerHigh
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.padding.normal
                                            StyledText { 
                                                text: Display.selectedMonitor ? `${Display.selectedMonitor.width}x${Display.selectedMonitor.height}` : "..."
                                                Layout.fillWidth: true 
                                                font.weight: 500
                                            }
                                            MaterialIcon { text: "expand_more"; opacity: 0.5 }
                                        }
                                        StateLayer { onClicked: resMenu.expanded = !resMenu.expanded }
                                    }
                                }

                                ColumnLayout {
                                    spacing: Appearance.spacing.extraSmall
                                    StyledText { text: qsTr("Refresh Rate"); opacity: 0.7; font.pointSize: Appearance.font.size.small }
                                    StyledRect {
                                        id: refreshButton
                                        Layout.fillWidth: true
                                        implicitHeight: 45
                                        radius: Appearance.rounding.small
                                        color: Colours.tPalette.m3surfaceContainerHigh
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.padding.normal
                                            StyledText { 
                                                text: Display.selectedMonitor && !isNaN(Display.selectedMonitor.refreshRate) ? `${Math.round(Display.selectedMonitor.refreshRate)} Hz` : "..."
                                                Layout.fillWidth: true 
                                                font.weight: 500
                                            }
                                            MaterialIcon { text: "expand_more"; opacity: 0.5 }
                                        }
                                        StateLayer { onClicked: refreshMenu.expanded = !refreshMenu.expanded }
                                    }
                                }

                                ColumnLayout {
                                    spacing: Appearance.spacing.extraSmall
                                    StyledText { text: qsTr("Manual (e.g. 1920x1080@60)"); opacity: 0.7; font.pointSize: Appearance.font.size.small }
                                    StyledRect {
                                        Layout.fillWidth: true
                                        implicitHeight: 45
                                        radius: Appearance.rounding.small
                                        color: Colours.tPalette.m3surfaceContainerHigh
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.padding.normal
                                            StyledTextField {
                                                id: manualResInput
                                                Layout.fillWidth: true
                                                placeholderText: qsTr("Resolution...")
                                                onAccepted: {
                                                    if (Display.selectedMonitor && text) {
                                                        Display.setManualResolution(Display.selectedMonitor.name, text);
                                                    }
                                                }
                                            }
                                            IconTextButton {
                                                icon: "check"
                                                text: ""
                                                onClicked: {
                                                    if (Display.selectedMonitor && manualResInput.text) {
                                                        Display.setManualResolution(Display.selectedMonitor.name, manualResInput.text);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Scaling Section
                        SectionContainer {
                            SectionHeader { title: qsTr("Scaling") }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small
                                RowLayout {
                                    StyledText { text: qsTr("Scale"); Layout.fillWidth: true; font.weight: 500 }
                                    StyledText { 
                                        text: Display.selectedMonitor ? `${Math.round(Display.selectedMonitor.scale * 100)}%` : "..."
                                        color: Colours.palette.m3primary
                                        font.weight: 600
                                    }
                                }
                                StyledSlider {
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 2
                                    value: Display.selectedMonitor ? Display.selectedMonitor.scale : 1
                                    onMoved: if (Display.selectedMonitor) Display.setScale(Display.selectedMonitor.name, value)
                                }
                            }
                        }

                        // Information Section
                        SectionContainer {
                            SectionHeader { title: qsTr("Identity") }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small
                                PropertyRow { label: qsTr("Name"); value: Display.selectedMonitor ? Display.selectedMonitor.name : "..." }
                                PropertyRow { label: qsTr("Serial"); value: Display.selectedMonitor ? Display.selectedMonitor.serialNumber : "..." }
                                PropertyRow { 
                                    label: qsTr("Type"); 
                                    value: Display.selectedMonitor && Display.selectedMonitor.name.startsWith("eDP") ? qsTr("Built-in") : qsTr("External") 
                                }
                            }
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !Display.selectedMonitor
                        spacing: Appearance.spacing.normal
                        Item { implicitHeight: 40 }
                        MaterialIcon {
                            text: "monitor"
                            font.pointSize: 48
                            opacity: 0.2
                            Layout.alignment: Qt.AlignCenter
                        }
                        StyledText {
                            text: qsTr("Select a monitor to configure")
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            opacity: 0.5
                        }
                    }
                }
            }
        }
    }

    // Menus
    Menu {
        id: resMenu
        expanded: false
        anchors.top: resButton.bottom
        anchors.left: resButton.left
        anchors.right: resButton.right
        z: 10
        
        items: {
            if (!Display.selectedMonitor) return [];
            const resList = [];
            const modes = Display.selectedMonitor.availableModes || [];
            if (modes.length === 0) return [];
            const shown = new Set();
            for (let i = 0; i < modes.length; i++) {
                const res = modes[i].split('@')[0];
                if (!shown.has(res)) {
                    const mi = menuItemComponent.createObject(resMenu, { text: res });
                    mi.clicked.connect(() => {
                        Display.setResolution(Display.selectedMonitor.name, res);
                        resMenu.expanded = false;
                    });
                    resList.push(mi);
                    shown.add(res);
                }
            }
            return resList;
        }
    }

    Menu {
        id: refreshMenu
        expanded: false
        anchors.top: refreshButton.bottom
        anchors.left: refreshButton.left
        anchors.right: refreshButton.right
        z: 10
        
        items: {
            const modes = Display.selectedMonitor.availableModes || [];
            if (modes.length === 0) return [];
            const rateList = [];
            const currentRes = `${Display.selectedMonitor.width}x${Display.selectedMonitor.height}`;
            for (let i = 0; i < modes.length; i++) {
                if (modes[i].startsWith(currentRes)) {
                    const rateStr = modes[i].split('@')[1].replace('Hz', '');
                    const mi = menuItemComponent.createObject(refreshMenu, { 
                        text: `${Math.round(parseFloat(rateStr))} Hz` 
                    });
                    mi.clicked.connect(() => {
                        // Use full mode string for better precision if possible
                        Display.setResolution(Display.selectedMonitor.name, modes[i]);
                        refreshMenu.expanded = false;
                    });
                    rateList.push(mi);
                }
            }
            return rateList;
        }
    }
}
