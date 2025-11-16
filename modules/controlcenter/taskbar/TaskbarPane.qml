pragma ComponentBehavior: Bound

import ".."
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

RowLayout {
    id: root

    required property Session session

    // Clock
    property bool clockShowIcon: Config.bar.clock.showIcon ?? true

    // Bar Behavior
    property bool persistent: Config.bar.persistent ?? true
    property bool showOnHover: Config.bar.showOnHover ?? true
    property int dragThreshold: Config.bar.dragThreshold ?? 20

    // Status Icons
    property bool showAudio: Config.bar.status.showAudio ?? true
    property bool showMicrophone: Config.bar.status.showMicrophone ?? true
    property bool showKbLayout: Config.bar.status.showKbLayout ?? false
    property bool showNetwork: Config.bar.status.showNetwork ?? true
    property bool showBluetooth: Config.bar.status.showBluetooth ?? true
    property bool showBattery: Config.bar.status.showBattery ?? true
    property bool showLockStatus: Config.bar.status.showLockStatus ?? true

    // Tray Settings
    property bool trayBackground: Config.bar.tray.background ?? false
    property bool trayCompact: Config.bar.tray.compact ?? false
    property bool trayRecolour: Config.bar.tray.recolour ?? false

    // Workspaces
    property int workspacesShown: Config.bar.workspaces.shown ?? 5
    property bool workspacesActiveIndicator: Config.bar.workspaces.activeIndicator ?? true
    property bool workspacesOccupiedBg: Config.bar.workspaces.occupiedBg ?? false
    property bool workspacesShowWindows: Config.bar.workspaces.showWindows ?? false
    property bool workspacesPerMonitor: Config.bar.workspaces.perMonitorWorkspaces ?? true

    anchors.fill: parent

    spacing: 0

    Component.onCompleted: {
        // Update entries
        if (Config.bar.entries) {
            entriesModel.clear();
            for (let i = 0; i < Config.bar.entries.length; i++) {
                const entry = Config.bar.entries[i];
                entriesModel.append({
                    id: entry.id,
                    enabled: entry.enabled !== false
                });
            }
        }
    }

    function saveConfig(entryIndex, entryEnabled) {
        // Update clock setting
        Config.bar.clock.showIcon = root.clockShowIcon;

        // Update bar behavior
        Config.bar.persistent = root.persistent;
        Config.bar.showOnHover = root.showOnHover;
        Config.bar.dragThreshold = root.dragThreshold;

        // Update status icons
        Config.bar.status.showAudio = root.showAudio;
        Config.bar.status.showMicrophone = root.showMicrophone;
        Config.bar.status.showKbLayout = root.showKbLayout;
        Config.bar.status.showNetwork = root.showNetwork;
        Config.bar.status.showBluetooth = root.showBluetooth;
        Config.bar.status.showBattery = root.showBattery;
        Config.bar.status.showLockStatus = root.showLockStatus;

        // Update tray settings
        Config.bar.tray.background = root.trayBackground;
        Config.bar.tray.compact = root.trayCompact;
        Config.bar.tray.recolour = root.trayRecolour;

        // Update workspaces
        Config.bar.workspaces.shown = root.workspacesShown;
        Config.bar.workspaces.activeIndicator = root.workspacesActiveIndicator;
        Config.bar.workspaces.occupiedBg = root.workspacesOccupiedBg;
        Config.bar.workspaces.showWindows = root.workspacesShowWindows;
        Config.bar.workspaces.perMonitorWorkspaces = root.workspacesPerMonitor;

        // Update entries from the model (same approach as clock - use provided value if available)
        const entries = [];
        for (let i = 0; i < entriesModel.count; i++) {
            const entry = entriesModel.get(i);
            // If this is the entry being updated, use the provided value (same as clock toggle reads from switch)
            // Otherwise use the value from the model
            let enabled = entry.enabled;
            if (entryIndex !== undefined && i === entryIndex) {
                enabled = entryEnabled;
            }
            entries.push({
                id: entry.id,
                enabled: enabled
            });
        }
        Config.bar.entries = entries;
    }

    ListModel {
        id: entriesModel
    }

    Item {
        id: leftTaskbarItem
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        ClippingRectangle {
            id: leftTaskbarClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: leftTaskbarBorder.innerRadius
            color: "transparent"

            Loader {
                id: leftTaskbarLoader

                anchors.fill: parent
                anchors.margins: Appearance.padding.large + Appearance.padding.normal
                anchors.leftMargin: Appearance.padding.large
                anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2

                asynchronous: true
                sourceComponent: leftTaskbarContentComponent
            }
        }

        InnerBorder {
            id: leftTaskbarBorder
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }

        Component {
            id: leftTaskbarContentComponent

            StyledFlickable {
                id: sidebarFlickable
                flickableDirection: Flickable.VerticalFlick
                contentHeight: sidebarLayout.height

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: sidebarFlickable
                }

                ColumnLayout {
                    id: sidebarLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    spacing: Appearance.spacing.small

                    RowLayout {
                spacing: Appearance.spacing.smaller

                StyledText {
                    text: qsTr("Settings")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            CollapsibleSection {
                id: clockSection
                title: qsTr("Clock")
                description: qsTr("Clock display settings")

                RowLayout {
                    id: clockRow

                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.padding.large
                    Layout.rightMargin: Appearance.padding.large
                    Layout.alignment: Qt.AlignVCenter

                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Show clock icon")
                    }

                    StyledSwitch {
                        id: clockShowIconSwitch
                        checked: root.clockShowIcon
                        onToggled: {
                            root.clockShowIcon = checked;
                            root.saveConfig();
                        }
                    }
                }
            }

            CollapsibleSection {
                id: barBehaviorSection
                title: qsTr("Bar Behavior")

                SwitchRow {
                    label: qsTr("Persistent")
                    checked: root.persistent
                    onToggled: checked => {
                        root.persistent = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show on hover")
                    checked: root.showOnHover
                    onToggled: checked => {
                        root.showOnHover = checked;
                        root.saveConfig();
                    }
                }

                SectionContainer {
                    contentSpacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                text: qsTr("Drag threshold")
                                font.pointSize: Appearance.font.size.normal
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledRect {
                                Layout.preferredWidth: 70
                                implicitHeight: dragThresholdInput.implicitHeight + Appearance.padding.small * 2
                                color: dragThresholdInputHover.containsMouse || dragThresholdInput.activeFocus 
                                       ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
                                       : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                radius: Appearance.rounding.small
                                border.width: 1
                                border.color: dragThresholdInput.activeFocus 
                                              ? Colours.palette.m3primary
                                              : Qt.alpha(Colours.palette.m3outline, 0.3)

                                Behavior on color { CAnim {} }
                                Behavior on border.color { CAnim {} }

                                MouseArea {
                                    id: dragThresholdInputHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.IBeamCursor
                                    acceptedButtons: Qt.NoButton
                                }

                                StyledTextField {
                                    id: dragThresholdInput
                                    anchors.centerIn: parent
                                    width: parent.width - Appearance.padding.normal
                                    horizontalAlignment: TextInput.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 100 }
                                    
                                    Component.onCompleted: {
                                        text = root.dragThreshold.toString();
                                    }
                                    
                                    onTextChanged: {
                                        if (activeFocus) {
                                            const val = parseInt(text);
                                            if (!isNaN(val) && val >= 0 && val <= 100) {
                                                root.dragThreshold = val;
                                                root.saveConfig();
                                            }
                                        }
                                    }
                                    onEditingFinished: {
                                        const val = parseInt(text);
                                        if (isNaN(val) || val < 0 || val > 100) {
                                            text = root.dragThreshold.toString();
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: "px"
                                color: Colours.palette.m3outline
                                font.pointSize: Appearance.font.size.normal
                            }
                        }

                        StyledSlider {
                            id: dragThresholdSlider

                            Layout.fillWidth: true
                            implicitHeight: Appearance.padding.normal * 3

                            from: 0
                            to: 100
                            value: root.dragThreshold
                            onMoved: {
                                root.dragThreshold = Math.round(dragThresholdSlider.value);
                                if (!dragThresholdInput.activeFocus) {
                                    dragThresholdInput.text = Math.round(dragThresholdSlider.value).toString();
                                }
                                root.saveConfig();
                            }
                        }
                    }
                }
            }

            CollapsibleSection {
                id: statusIconsSection
                title: qsTr("Status Icons")

                SwitchRow {
                    label: qsTr("Show audio")
                    checked: root.showAudio
                    onToggled: checked => {
                        root.showAudio = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show microphone")
                    checked: root.showMicrophone
                    onToggled: checked => {
                        root.showMicrophone = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show keyboard layout")
                    checked: root.showKbLayout
                    onToggled: checked => {
                        root.showKbLayout = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show network")
                    checked: root.showNetwork
                    onToggled: checked => {
                        root.showNetwork = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show bluetooth")
                    checked: root.showBluetooth
                    onToggled: checked => {
                        root.showBluetooth = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show battery")
                    checked: root.showBattery
                    onToggled: checked => {
                        root.showBattery = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Show lock status")
                    checked: root.showLockStatus
                    onToggled: checked => {
                        root.showLockStatus = checked;
                        root.saveConfig();
                    }
                }
            }

            CollapsibleSection {
                id: traySettingsSection
                title: qsTr("Tray Settings")

                SwitchRow {
                    label: qsTr("Background")
                    checked: root.trayBackground
                    onToggled: checked => {
                        root.trayBackground = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Compact")
                    checked: root.trayCompact
                    onToggled: checked => {
                        root.trayCompact = checked;
                        root.saveConfig();
                    }
                }

                SwitchRow {
                    label: qsTr("Recolour")
                    checked: root.trayRecolour
                    onToggled: checked => {
                        root.trayRecolour = checked;
                        root.saveConfig();
                    }
                }
            }

            CollapsibleSection {
                id: workspacesSection
                title: qsTr("Workspaces")

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesShownRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesShownRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Shown")
                        }

                        CustomSpinBox {
                            min: 1
                            max: 20
                            value: root.workspacesShown
                            onValueModified: value => {
                                root.workspacesShown = value;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesActiveIndicatorRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesActiveIndicatorRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Active indicator")
                        }

                        StyledSwitch {
                            checked: root.workspacesActiveIndicator
                            onToggled: {
                                root.workspacesActiveIndicator = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesOccupiedBgRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesOccupiedBgRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Occupied background")
                        }

                        StyledSwitch {
                            checked: root.workspacesOccupiedBg
                            onToggled: {
                                root.workspacesOccupiedBg = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesShowWindowsRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesShowWindowsRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Show windows")
                        }

                        StyledSwitch {
                            checked: root.workspacesShowWindows
                            onToggled: {
                                root.workspacesShowWindows = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: workspacesPerMonitorRow.implicitHeight + Appearance.padding.large * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer

                    Behavior on implicitHeight {
                        Anim {}
                    }

                    RowLayout {
                        id: workspacesPerMonitorRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.large
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Per monitor workspaces")
                        }

                        StyledSwitch {
                            checked: root.workspacesPerMonitor
                            onToggled: {
                                root.workspacesPerMonitor = checked;
                                root.saveConfig();
                            }
                        }
                    }
                }
            }
        }
        }
        }
    }

    Item {
        id: rightTaskbarItem
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            id: rightTaskbarClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: rightTaskbarBorder.innerRadius
            color: "transparent"

            Loader {
                id: rightTaskbarLoader

                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 2

                asynchronous: true
                sourceComponent: rightTaskbarContentComponent
            }
        }

        InnerBorder {
            id: rightTaskbarBorder

            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: rightTaskbarContentComponent

            StyledFlickable {
                flickableDirection: Flickable.VerticalFlick
                contentHeight: contentLayout.height

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                ColumnLayout {
                    id: contentLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "task_alt"
                    font.pointSize: Appearance.font.size.extraLarge * 3
                    font.bold: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Taskbar Settings")
                    font.pointSize: Appearance.font.size.large
                    font.bold: true
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Clock")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.clockShowIcon ? qsTr("Clock icon enabled") : qsTr("Clock icon disabled")
                    color: Colours.palette.m3outline
                }

                StyledText {
                    Layout.topMargin: Appearance.spacing.large
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Taskbar Entries")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Configure which entries appear in the taskbar")
                    color: Colours.palette.m3outline
                }

            }
        }
        }
    }
}
