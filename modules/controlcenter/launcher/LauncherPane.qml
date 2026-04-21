pragma ComponentBehavior: Bound

import ".."
import "../components"
import "../../launcher/services"
import "../../../utils/scripts/fuzzysort.js" as Fuzzy
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property Session session

    property var selectedApp: root.session.launcher.active
    property bool hideFromLauncherChecked: false
    property bool favouriteChecked: false
    property string searchText: ""
    property list<var> filteredApps: []

    function updateToggleState() {
        if (!root.selectedApp) {
            root.hideFromLauncherChecked = false;
            root.favouriteChecked = false;
            return;
        }

        const appId = root.selectedApp.id || root.selectedApp.entry?.id;

        root.hideFromLauncherChecked = GlobalConfig.launcher.hiddenApps && GlobalConfig.launcher.hiddenApps.length > 0 && Strings.testRegexList(GlobalConfig.launcher.hiddenApps, appId);
        root.favouriteChecked = GlobalConfig.launcher.favouriteApps && GlobalConfig.launcher.favouriteApps.length > 0 && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appId);
    }

    function saveHiddenApps(isHidden) {
        if (!root.selectedApp) {
            return;
        }

        const appId = root.selectedApp.id || root.selectedApp.entry?.id;

        const hiddenApps = GlobalConfig.launcher.hiddenApps ? [...GlobalConfig.launcher.hiddenApps] : [];

        if (isHidden) {
            if (!hiddenApps.includes(appId)) {
                hiddenApps.push(appId);
            }
        } else {
            const index = hiddenApps.indexOf(appId);
            if (index !== -1) {
                hiddenApps.splice(index, 1);
            }
        }

        GlobalConfig.launcher.hiddenApps = hiddenApps;
    }

    function filterApps(search: string): list<var> {
        if (!search || search.trim() === "") {
            const apps = [];
            for (let i = 0; i < allAppsDb.apps.length; i++) {
                apps.push(allAppsDb.apps[i]);
            }
            return apps;
        }

        if (!allAppsDb.apps || allAppsDb.apps.length === 0) {
            return [];
        }

        const preparedApps = [];
        for (let i = 0; i < allAppsDb.apps.length; i++) {
            const app = allAppsDb.apps[i];
            const name = app.name || app.entry?.name || "";
            preparedApps.push({
                _item: app,
                name: Fuzzy.prepare(name)
            });
        }

        const results = Fuzzy.go(search, preparedApps, {
            all: true,
            keys: ["name"],
            scoreFn: r => r[0].score
        });

        return results.sort((a, b) => b._score - a._score).map(r => r.obj._item);
    }

    function updateFilteredApps() {
        filteredApps = filterApps(searchText);
    }

    anchors.fill: parent

    onSelectedAppChanged: {
        root.session.launcher.active = root.selectedApp;
        updateToggleState();
    }

    onSearchTextChanged: {
        updateFilteredApps();
    }

    Component.onCompleted: {
        updateFilteredApps();
    }

    Connections {
        function onActiveChanged() {
            root.selectedApp = root.session.launcher.active;
            updateToggleState();
        }

        target: root.session.launcher
    }

    AppDb {
        id: allAppsDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: DesktopEntries.applications.values
    }

    Connections {
        function onAppsChanged() {
            updateFilteredApps();
        }

        target: allAppsDb
    }

    SplitPaneLayout {
        anchors.fill: parent

        leftContent: Component {
            ColumnLayout {
                id: leftLauncherLayout

                anchors.fill: parent

                spacing: Tokens.spacing.small

                RowLayout {
                    spacing: Tokens.spacing.smaller

                    StyledText {
                        text: qsTr("Launcher")
                        font.pointSize: Tokens.font.size.large
                        font.weight: 500
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ToggleButton {
                        toggled: !root.session.launcher.active
                        icon: "settings"
                        accent: "Primary"
                        iconSize: Tokens.font.size.normal
                        horizontalPadding: Tokens.padding.normal
                        verticalPadding: Tokens.padding.smaller
                        tooltip: qsTr("Launcher settings")

                        onClicked: {
                            if (root.session.launcher.active) {
                                root.session.launcher.active = null;
                            } else {
                                if (root.filteredApps.length > 0) {
                                    root.session.launcher.active = root.filteredApps[0];
                                }
                            }
                        }
                    }
                }

                StyledText {
                    Layout.topMargin: Tokens.spacing.large
                    text: qsTr("Applications (%1)").arg(root.searchText ? root.filteredApps.length : allAppsDb.apps.length)
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 500
                }

                StyledText {
                    text: qsTr("All applications available in the launcher")
                    color: Colours.palette.m3outline
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.normal
                    Layout.bottomMargin: Tokens.spacing.small

                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                    radius: Tokens.rounding.full

                    implicitHeight: Math.max(searchIcon.implicitHeight, searchField.implicitHeight, clearIcon.implicitHeight)

                    MaterialIcon {
                        id: searchIcon

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.padding.normal

                        text: "search"
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledTextField {
                        id: searchField

                        anchors.left: searchIcon.right
                        anchors.right: clearIcon.left
                        anchors.leftMargin: Tokens.spacing.small
                        anchors.rightMargin: Tokens.spacing.small

                        topPadding: Tokens.padding.normal
                        bottomPadding: Tokens.padding.normal

                        placeholderText: qsTr("Search applications...")

                        onTextChanged: {
                            root.searchText = text;
                        }
                    }

                    MaterialIcon {
                        id: clearIcon

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.padding.normal

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

                Loader {
                    id: appsListLoader

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    asynchronous: true
                    active: true

                    sourceComponent: StyledListView {
                        id: appsListView

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        model: root.filteredApps
                        spacing: Tokens.spacing.small / 2
                        clip: true

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: parent
                        }

                        delegate: StyledRect {
                            required property var modelData

                            readonly property bool isSelected: root.selectedApp === modelData

                            width: parent ? parent.width : 0
                            implicitHeight: 40

                            color: isSelected ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : "transparent"
                            radius: Tokens.rounding.normal

                            opacity: 0

                            Component.onCompleted: {
                                opacity = 1;
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.OutCubic
                                }
                            }

                            StateLayer {
                                onClicked: {
                                    root.session.launcher.active = modelData;
                                }
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.normal

                                spacing: Tokens.spacing.normal

                                IconImage {
                                    asynchronous: true
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
                                    font.pointSize: Tokens.font.size.normal
                                }

                                Loader {
                                    readonly property bool isHidden: modelData ? Strings.testRegexList(GlobalConfig.launcher.hiddenApps, modelData.id) : false
                                    readonly property bool isFav: modelData ? Strings.testRegexList(GlobalConfig.launcher.favouriteApps, modelData.id) : false

                                    Layout.alignment: Qt.AlignVCenter
                                    asynchronous: true
                                    active: isHidden || isFav

                                    sourceComponent: isHidden ? hiddenIcon : (isFav ? favouriteIcon : null)
                                }

                                Component {
                                    id: hiddenIcon

                                    MaterialIcon {
                                        text: "visibility_off"
                                        fill: 1
                                        color: Colours.palette.m3primary
                                    }
                                }

                                Component {
                                    id: favouriteIcon

                                    MaterialIcon {
                                        text: "favorite"
                                        fill: 1
                                        color: Colours.palette.m3primary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        rightContent: Component {
            Item {
                id: rightLauncherPane

                property var pane: root.session.launcher.active
                property string paneId: pane ? (pane.id || pane.entry?.id || "") : ""
                property Component targetComponent: settings
                property Component nextComponent: settings
                property var displayedApp: null

                function getComponentForPane() {
                    return pane ? appDetails : settings;
                }

                Component.onCompleted: {
                    displayedApp = pane;
                    targetComponent = getComponentForPane();
                    nextComponent = targetComponent;
                }

                onPaneChanged: {
                    nextComponent = getComponentForPane();
                    paneId = pane ? (pane.id || pane.entry?.id || "") : "";
                }

                onDisplayedAppChanged: {
                    if (displayedApp) {
                        const appId = displayedApp.id || displayedApp.entry?.id;
                        root.hideFromLauncherChecked = GlobalConfig.launcher.hiddenApps && GlobalConfig.launcher.hiddenApps.length > 0 && Strings.testRegexList(GlobalConfig.launcher.hiddenApps, appId);
                        root.favouriteChecked = GlobalConfig.launcher.favouriteApps && GlobalConfig.launcher.favouriteApps.length > 0 && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appId);
                    } else {
                        root.hideFromLauncherChecked = false;
                        root.favouriteChecked = false;
                    }
                }

                Loader {
                    id: rightLauncherLoader

                    property var displayedApp: rightLauncherPane.displayedApp

                    anchors.fill: parent

                    asynchronous: true
                    opacity: 1
                    scale: 1
                    transformOrigin: Item.Center
                    clip: false

                    sourceComponent: rightLauncherPane.targetComponent
                    active: true

                    onItemChanged: {
                        if (item && rightLauncherPane.pane && rightLauncherPane.displayedApp !== rightLauncherPane.pane) {
                            rightLauncherPane.displayedApp = rightLauncherPane.pane;
                        }
                    }
                }

                Behavior on paneId {
                    PaneTransition {
                        target: rightLauncherLoader
                        propertyActions: [
                            PropertyAction {
                                target: rightLauncherPane
                                property: "displayedApp"
                                value: rightLauncherPane.pane
                            },
                            PropertyAction {
                                target: rightLauncherLoader
                                property: "active"
                                value: false
                            },
                            PropertyAction {
                                target: rightLauncherPane
                                property: "targetComponent"
                                value: rightLauncherPane.nextComponent
                            },
                            PropertyAction {
                                target: rightLauncherLoader
                                property: "active"
                                value: true
                            }
                        ]
                    }
                }
            }
        }
    }

    Component {
        id: settings

        StyledFlickable {
            id: settingsFlickable

            flickableDirection: Flickable.VerticalFlick
            contentHeight: settingsInner.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: settingsFlickable
            }

            Settings {
                id: settingsInner

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                session: root.session
            }
        }
    }

    Component {
        id: appDetails

        ColumnLayout {
            id: appDetailsLayout

            readonly property var displayedApp: parent && parent.displayedApp !== undefined ? parent.displayedApp : null

            anchors.fill: parent
            spacing: Tokens.spacing.normal

            SettingsHeader {
                Layout.leftMargin: Tokens.padding.large * 2
                Layout.rightMargin: Tokens.padding.large * 2
                Layout.topMargin: Tokens.padding.large * 2
                visible: displayedApp === null
                icon: "apps"
                title: qsTr("Launcher Applications")
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: Tokens.padding.large * 2
                Layout.rightMargin: Tokens.padding.large * 2
                Layout.topMargin: Tokens.padding.large * 2
                visible: displayedApp !== null
                implicitWidth: Math.max(appIconImage.implicitWidth, appTitleText.implicitWidth)
                implicitHeight: appIconImage.implicitHeight + Tokens.spacing.normal + appTitleText.implicitHeight

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.normal

                    IconImage {
                        id: appIconImage

                        asynchronous: true
                        Layout.alignment: Qt.AlignHCenter
                        implicitSize: Tokens.font.size.extraLarge * 3 * 2
                        source: {
                            const app = appDetailsLayout.displayedApp;
                            if (!app)
                                return "image-missing";
                            const entry = app.entry;
                            if (entry && entry.icon) {
                                return Quickshell.iconPath(entry.icon, "image-missing");
                            }
                            return "image-missing";
                        }
                    }

                    StyledText {
                        id: appTitleText

                        Layout.alignment: Qt.AlignHCenter
                        text: displayedApp ? (displayedApp.name || displayedApp.entry?.name || qsTr("Application Details")) : ""
                        font.pointSize: Tokens.font.size.large
                        font.bold: true
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Tokens.spacing.large
                Layout.leftMargin: Tokens.padding.large * 2
                Layout.rightMargin: Tokens.padding.large * 2

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
                        spacing: Tokens.spacing.normal

                        SwitchRow {
                            Layout.topMargin: Tokens.spacing.normal
                            visible: appDetailsLayout.displayedApp !== null
                            label: qsTr("Mark as favourite")
                            checked: root.favouriteChecked
                            // disabled if:
                            // * app is hidden
                            // * app isn't in favouriteApps array but marked as favourite anyway
                            // ^^^ This means that this app is favourited because of a regex check
                            //     this button can not toggle regexed apps
                            enabled: appDetailsLayout.displayedApp !== null && !root.hideFromLauncherChecked && (GlobalConfig.launcher.favouriteApps.indexOf(appDetailsLayout.displayedApp.id || appDetailsLayout.displayedApp.entry?.id) !== -1 || !root.favouriteChecked)
                            opacity: enabled ? 1 : 0.6
                            onToggled: checked => {
                                root.favouriteChecked = checked;
                                const app = appDetailsLayout.displayedApp;
                                if (app) {
                                    const appId = app.id || app.entry?.id;
                                    const favouriteApps = GlobalConfig.launcher.favouriteApps ? [...GlobalConfig.launcher.favouriteApps] : [];
                                    if (checked) {
                                        if (!favouriteApps.includes(appId)) {
                                            favouriteApps.push(appId);
                                        }
                                    } else {
                                        const index = favouriteApps.indexOf(appId);
                                        if (index !== -1) {
                                            favouriteApps.splice(index, 1);
                                        }
                                    }
                                    GlobalConfig.launcher.favouriteApps = favouriteApps;
                                }
                            }
                        }
                        SwitchRow {
                            Layout.topMargin: Tokens.spacing.normal
                            visible: appDetailsLayout.displayedApp !== null
                            label: qsTr("Hide from launcher")
                            checked: root.hideFromLauncherChecked
                            // disabled if:
                            // * app is favourited
                            // * app isn't in hiddenApps array but marked as hidden anyway
                            // ^^^ This means that this app is hidden because of a regex check
                            //     this button can not toggle regexed apps
                            enabled: appDetailsLayout.displayedApp !== null && !root.favouriteChecked && (GlobalConfig.launcher.hiddenApps.indexOf(appDetailsLayout.displayedApp.id || appDetailsLayout.displayedApp.entry?.id) !== -1 || !root.hideFromLauncherChecked)
                            opacity: enabled ? 1 : 0.6
                            onToggled: checked => {
                                root.hideFromLauncherChecked = checked;
                                const app = appDetailsLayout.displayedApp;
                                if (app) {
                                    const appId = app.id || app.entry?.id;
                                    const hiddenApps = GlobalConfig.launcher.hiddenApps ? [...GlobalConfig.launcher.hiddenApps] : [];
                                    if (checked) {
                                        if (!hiddenApps.includes(appId)) {
                                            hiddenApps.push(appId);
                                        }
                                    } else {
                                        const index = hiddenApps.indexOf(appId);
                                        if (index !== -1) {
                                            hiddenApps.splice(index, 1);
                                        }
                                    }
                                    GlobalConfig.launcher.hiddenApps = hiddenApps;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
