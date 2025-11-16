pragma ComponentBehavior: Bound

import ".."
import "../../launcher/services"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Caelestia
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../../../utils/scripts/fuzzysort.js" as Fuzzy

RowLayout {
    id: root

    required property Session session

    property var selectedApp: null
    property bool hideFromLauncherChecked: false

    anchors.fill: parent

    spacing: 0

    function updateToggleState() {
        if (!root.selectedApp) {
            root.hideFromLauncherChecked = false;
            return;
        }

        const appId = root.selectedApp.id || root.selectedApp.entry?.id;

        if (Config.launcher.hiddenApps && Config.launcher.hiddenApps.length > 0) {
            root.hideFromLauncherChecked = Config.launcher.hiddenApps.includes(appId);
        } else {
            root.hideFromLauncherChecked = false;
        }
    }

    function saveHiddenApps(isHidden) {
        if (!root.selectedApp) {
            return;
        }

        const appId = root.selectedApp.id || root.selectedApp.entry?.id;

        // Create a new array to ensure change detection
        const hiddenApps = Config.launcher.hiddenApps ? [...Config.launcher.hiddenApps] : [];

        if (isHidden) {
            // Add to hiddenApps if not already there
            if (!hiddenApps.includes(appId)) {
                hiddenApps.push(appId);
            }
        } else {
            // Remove from hiddenApps
            const index = hiddenApps.indexOf(appId);
            if (index !== -1) {
                hiddenApps.splice(index, 1);
            }
        }

        // Update Config to trigger save
        Config.launcher.hiddenApps = hiddenApps;
    }

    onSelectedAppChanged: {
        updateToggleState();
    }

    AppDb {
        id: allAppsDb

        path: `${Paths.state}/apps.sqlite`
        entries: DesktopEntries.applications.values  // No filter - show all apps
    }

    property string searchText: ""

    function filterApps(search: string): list<var> {
        // If search is empty, return all apps directly
        if (!search || search.trim() === "") {
            // Convert QQmlListProperty to array
            const apps = [];
            for (let i = 0; i < allAppsDb.apps.length; i++) {
                apps.push(allAppsDb.apps[i]);
            }
            return apps;
        }

        if (!allAppsDb.apps || allAppsDb.apps.length === 0) {
            return [];
        }

        // Prepare apps for fuzzy search
        const preparedApps = [];
        for (let i = 0; i < allAppsDb.apps.length; i++) {
            const app = allAppsDb.apps[i];
            const name = app.name || app.entry?.name || "";
            preparedApps.push({
                _item: app,
                name: Fuzzy.prepare(name)
            });
        }

        // Perform fuzzy search
        const results = Fuzzy.go(search, preparedApps, {
            all: true,
            keys: ["name"],
            scoreFn: r => r[0].score
        });

        // Return sorted by score (highest first)
        return results
            .sort((a, b) => b._score - a._score)
            .map(r => r.obj._item);
    }

    property list<var> filteredApps: []

    function updateFilteredApps() {
        filteredApps = filterApps(searchText);
    }

    onSearchTextChanged: {
        updateFilteredApps();
    }

    Component.onCompleted: {
        updateFilteredApps();
    }

    Connections {
        target: allAppsDb
        function onAppsChanged() {
            updateFilteredApps();
        }
    }

    Item {
        id: leftLauncherItem
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        ClippingRectangle {
            id: leftLauncherClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: leftLauncherBorder.innerRadius
            color: "transparent"

            Loader {
                id: leftLauncherLoader

                anchors.fill: parent
                anchors.margins: Appearance.padding.large + Appearance.padding.normal
                anchors.leftMargin: Appearance.padding.large
                anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2
                anchors.bottomMargin: 0

                asynchronous: true
                sourceComponent: leftContentComponent
            }
        }

        InnerBorder {
            id: leftLauncherBorder
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }

        Component {
            id: leftContentComponent

            ColumnLayout {
                anchors.fill: parent

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

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Applications (%1)").arg(root.searchText ? root.filteredApps.length : allAppsDb.apps.length)
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
            }

            StyledText {
                text: qsTr("All applications available in the launcher")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.normal
                Layout.bottomMargin: Appearance.spacing.small

                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                radius: Appearance.rounding.full

                implicitHeight: Math.max(searchIcon.implicitHeight, searchField.implicitHeight, clearIcon.implicitHeight)

                MaterialIcon {
                    id: searchIcon

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.padding.normal

                    text: "search"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledTextField {
                    id: searchField

                    anchors.left: searchIcon.right
                    anchors.right: clearIcon.left
                    anchors.leftMargin: Appearance.spacing.small
                    anchors.rightMargin: Appearance.spacing.small

                    topPadding: Appearance.padding.normal
                    bottomPadding: Appearance.padding.normal

                    placeholderText: qsTr("Search applications...")

                    onTextChanged: {
                        root.searchText = text;
                    }
                }

                MaterialIcon {
                    id: clearIcon

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.padding.normal

                    width: searchField.text ? implicitWidth : implicitWidth / 2
                    opacity: {
                        if (!searchField.text)
                            return 0;
                        if (clearMouse.pressed)
                            return 0.7;
                        if (clearMouse.containsMouse)
                            return 0.8;
                        return 1;
                    }

                    text: "close"
                    color: Colours.palette.m3onSurfaceVariant

                    MouseArea {
                        id: clearMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: searchField.text ? Qt.PointingHandCursor : undefined

                        onClicked: searchField.text = ""
                    }

                    Behavior on width {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.anim.durations.small
                        }
                    }
                }
            }

            StyledListView {
                id: appsListView
                Layout.fillWidth: true
                Layout.fillHeight: true

                model: root.filteredApps
                spacing: Appearance.spacing.small / 2
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: parent
                }

                delegate: StyledRect {
                    required property var modelData

                    width: parent ? parent.width : 0

                    readonly property bool isSelected: root.selectedApp === modelData

                    color: isSelected ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : "transparent"
                    radius: Appearance.rounding.normal

                    opacity: 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1000
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: {
                        opacity = 1;
                    }

                    StateLayer {
                        function onClicked(): void {
                            root.selectedApp = modelData;
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        spacing: Appearance.spacing.normal

                        IconImage {
                            Layout.alignment: Qt.AlignVCenter
                            implicitSize: 32
                            source: {
                                const entry = modelData.entry;
                                return entry ? Quickshell.iconPath(entry.icon, "image-missing") : "image-missing";
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name || modelData.entry?.name || qsTr("Unknown")
                            font.pointSize: Appearance.font.size.normal
                        }
                    }

                    implicitHeight: 40
                }
            }
        }
        }
    }

    Item {
        id: rightLauncherItem
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            id: rightLauncherClippingRect
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Appearance.padding.normal / 2

            radius: rightLauncherBorder.innerRadius
            color: "transparent"

            Loader {
                id: rightLauncherLoader

                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 2

                asynchronous: true
                sourceComponent: rightContentComponent
            }
        }

        InnerBorder {
            id: rightLauncherBorder

            leftThickness: Appearance.padding.normal / 2
        }

        Component {
            id: rightContentComponent

            ColumnLayout {
                anchors.fill: parent

                spacing: Appearance.spacing.normal

                Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: Appearance.padding.large * 2
                Layout.rightMargin: Appearance.padding.large * 2
                Layout.topMargin: Appearance.padding.large * 2
                implicitWidth: iconLoader.implicitWidth
                implicitHeight: iconLoader.implicitHeight

                Loader {
                    id: iconLoader
                    sourceComponent: root.selectedApp ? appIconComponent : defaultIconComponent
                }

                Component {
                    id: appIconComponent
                    IconImage {
                        implicitSize: Appearance.font.size.extraLarge * 3 * 2
                        source: {
                            if (!root.selectedApp) return "image-missing";
                            const entry = root.selectedApp.entry;
                            if (entry && entry.icon) {
                                return Quickshell.iconPath(entry.icon, "image-missing");
                            }
                            return "image-missing";
                        }
                    }
                }

                Component {
                    id: defaultIconComponent
                    MaterialIcon {
                        text: "apps"
                        font.pointSize: Appearance.font.size.extraLarge * 3
                        font.bold: true
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: Appearance.padding.large * 2
                Layout.rightMargin: Appearance.padding.large * 2
                text: root.selectedApp ? (root.selectedApp.name || root.selectedApp.entry?.name || qsTr("Application Details")) : qsTr("Launcher Applications")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Appearance.spacing.large
                Layout.leftMargin: Appearance.padding.large * 2
                Layout.rightMargin: Appearance.padding.large * 2

                StyledFlickable {
                    id: detailsFlickable
                    anchors.fill: parent
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: debugLayout.height

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: parent
                    }

                    ColumnLayout {
                        id: debugLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: Appearance.spacing.normal

                        SwitchRow {
                            Layout.topMargin: Appearance.spacing.normal
                            visible: root.selectedApp !== null
                            label: qsTr("Hide from launcher")
                            checked: root.hideFromLauncherChecked
                            enabled: root.selectedApp !== null
                            onToggled: checked => {
                                root.hideFromLauncherChecked = checked;
                                root.saveHiddenApps(checked);
                            }
                        }

                    }
                }
            }
        }
        }
    }
}
