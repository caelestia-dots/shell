pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    property var sortedEntries: Config.bar.entries.reduce((acc, entry) => {
        (acc[entry.alignment] || acc.top).push(entry);
        return acc;
    }, { top: [], center: [], bottom: [] })

    property var topEntries: sortedEntries.top
    property var centerEntries: sortedEntries.center
    property var bottomEntries: sortedEntries.bottom

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.bottomMargin: Appearance.padding.large
    anchors.topMargin: Appearance.padding.large

    Component.onCompleted: implicitWidth = Qt.binding(() =>  Math.max(topSection.implicitWidth, centerSection.implicitWidth, bottomSection.implicitWidth) + Config.border.thickness * 2)

    BarSection {
        id: topSection

        model: root.topEntries
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    BarSection {
        id: centerSection

        model: root.centerEntries
        anchors.top: topSection.bottom
        anchors.bottom: bottomSection.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.normal
        anchors.bottomMargin: Appearance.spacing.normal
    }

    BarSection {
        id: bottomSection

        model: root.bottomEntries
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    component BarSection: ColumnLayout {
        id: barSection

        required property var model
        spacing: Appearance.spacing.normal

        readonly property var componentMap: {
            "logo": osIconComponent,
            "workspaces": workspacesComponent,
            "activeWindow": activeWindowComponent,
            "tray": trayComponent,
            "clock": clockComponent,
            "statusIcons": statusIconsComponent,
            "power": powerComponent
        }

        Component {
            id: osIconComponent;
            OsIcon {}
        }
        Component {
            id: workspacesComponent;
            Workspaces { id: workspacesInner }
        }
        Component {
            id: activeWindowComponent
            ActiveWindow {
                Layout.fillHeight: true
                monitor: Brightness.getMonitorForScreen(root.screen)
            }
        }
        Component {
            id: trayComponent;
            Tray {}
        }
        Component {
            id: clockComponent;
            Clock {}
        }
        Component {
            id: statusIconsComponent;
            StatusIcons {}
        }
        Component {
            id: powerComponent
            Power {
                visibilities: root.visibilities
            }
        }

        Repeater {
            id: repeater
            model: barSection.model

            Loader {
                required property string id
                required property bool enabled

                active: enabled
                asynchronous: true
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: id === "activeWindow"
                sourceComponent: barSection.componentMap[id] || null
            }
        }
    }
}
