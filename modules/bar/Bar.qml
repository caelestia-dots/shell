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

        model: root.sortedEntries.top
        // model: root.topEntries
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    BarSection {
        id: centerSection

        // model: root.centerEntries
        model: root.sortedEntries.center
        anchors.top: topSection.bottom
        anchors.bottom: bottomSection.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Appearance.spacing.normal
        anchors.bottomMargin: Appearance.spacing.normal
    }

    BarSection {
        id: bottomSection

        model: root.sortedEntries.bottom
        // model: root.bottomEntries
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    component WrappedLoader: Loader {
        required property bool enabled

        active: enabled
        asynchronous: true
        Layout.alignment: Qt.AlignHCenter
    }

    component BarSection: ColumnLayout {
        id: barSection

        required property var model
        spacing: Appearance.spacing.normal

        Repeater {
            model: barSection.model

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "logo"
                    delegate: WrappedLoader {
                        sourceComponent: OsIcon {}
                    }
                }
                DelegateChoice {
                    roleValue: "workspaces"
                    delegate: WrappedLoader {
                        sourceComponent: Workspaces {}
                    }
                }
                DelegateChoice {
                    roleValue: "activeWindow"
                    delegate: WrappedLoader {
                        Layout.fillHeight: true
                        sourceComponent: ActiveWindow {
                            monitor: Brightness.getMonitorForScreen(root.screen)
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "tray"
                    delegate: WrappedLoader {
                        sourceComponent: Tray {}
                    }
                }
                DelegateChoice {
                    roleValue: "clock"
                    delegate: WrappedLoader {
                        sourceComponent: Clock {}
                    }
                }
                DelegateChoice {
                    roleValue: "statusIcons"
                    delegate: WrappedLoader {
                        sourceComponent: StatusIcons {}
                    }
                }
                DelegateChoice {
                    roleValue: "power"
                    delegate: WrappedLoader {
                        sourceComponent: Power {
                            visibilities: root.visibilities
                        }
                    }
                }
            }
        }
    }
}
