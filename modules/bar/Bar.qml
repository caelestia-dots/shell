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
    }

    BarSection {
        id: bottomSection

        model: root.bottomEntries
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    component BarSection: ColumnLayout {
        id: test
        required property var model
        spacing: Appearance.spacing.normal

        Repeater {
            model: test.model

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "logo"
                    delegate: Loader {
                        active: modelData.enabled
                        Layout.alignment: Qt.AlignHCenter

                        sourceComponent: OsIcon {}
                    }
                }

                DelegateChoice {
                    roleValue: "workspaces"
                    delegate: Loader {
                        active: modelData.enabled
                        Layout.alignment: Qt.AlignHCenter

                        sourceComponent: Workspaces {
                            id: workspacesInner
                        }
                    }
                }

                DelegateChoice {
                    roleValue: "activeWindow"
                    delegate: Loader {
                        active: modelData.enabled
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true

                        sourceComponent: ActiveWindow {
                            Layout.fillHeight: true
                            monitor: Brightness.getMonitorForScreen(root.screen)
                        }
                    }
                }

                DelegateChoice {
                    roleValue: "tray"
                    delegate: Loader {
                        active: modelData.enabled
                        Layout.alignment: Qt.AlignHCenter

                        sourceComponent: Tray {}
                    }
                }

                DelegateChoice {
                    roleValue: "clock"
                    delegate: Loader {
                        active: modelData.enabled
                        Layout.alignment: Qt.AlignHCenter

                        sourceComponent: Clock {}
                    }
                }

                DelegateChoice {
                    roleValue: "statusIcons"
                    delegate: Loader {
                        active: modelData.enabled
                        Layout.alignment: Qt.AlignHCenter

                        sourceComponent: StatusIcons {}
                    }
                }

                DelegateChoice {
                    roleValue: "power"
                    delegate: Loader {
                        active: modelData.enabled
                        Layout.alignment: Qt.AlignHCenter

                        sourceComponent: Power {
                            visibilities: root.visibilities
                        }
                    }
                }
            }
        }
    }
}
