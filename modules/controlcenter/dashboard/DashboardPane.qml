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

    // General Settings
    property bool enabled: Config.dashboard.enabled ?? true
    property bool showOnHover: Config.dashboard.showOnHover ?? true
    property int dragThreshold: Config.dashboard.dragThreshold ?? 50
    
    // Media Settings
    property int mediaUpdateInterval: Config.dashboard.mediaUpdateInterval ?? 500
    property int mediaWidth: Config.dashboard.sizes.mediaWidth ?? 200
    property int mediaCoverArtSize: Config.dashboard.sizes.mediaCoverArtSize ?? 150
    property int mediaProgressSweep: Config.dashboard.sizes.mediaProgressSweep ?? 180
    property int mediaProgressThickness: Config.dashboard.sizes.mediaProgressThickness ?? 8
    property int mediaVisualiserSize: Config.dashboard.sizes.mediaVisualiserSize ?? 80
    
    // Performance Resources
    property bool showBattery: Config.dashboard.performance.showBattery ?? false
    property bool showGpu: Config.dashboard.performance.showGpu ?? true
    property bool showCpu: Config.dashboard.performance.showCpu ?? true
    property bool showMemory: Config.dashboard.performance.showMemory ?? true
    property bool showStorage: Config.dashboard.performance.showStorage ?? false
    property int resourceSize: Config.dashboard.sizes.resourceSize ?? 200
    property int resourceProgessThickness: Config.dashboard.sizes.resourceProgessThickness ?? 10

    // Widget Sizes
    property int tabIndicatorHeight: Config.dashboard.sizes.tabIndicatorHeight ?? 3
    property int tabIndicatorSpacing: Config.dashboard.sizes.tabIndicatorSpacing ?? 5
    property int infoWidth: Config.dashboard.sizes.infoWidth ?? 200
    property int infoIconSize: Config.dashboard.sizes.infoIconSize ?? 25
    property int dateTimeWidth: Config.dashboard.sizes.dateTimeWidth ?? 110
    property int weatherWidth: Config.dashboard.sizes.weatherWidth ?? 250

    anchors.fill: parent

    function saveConfig() {
        Config.dashboard.enabled = root.enabled;
        Config.dashboard.showOnHover = root.showOnHover;
        Config.dashboard.dragThreshold = root.dragThreshold;
        Config.dashboard.mediaUpdateInterval = root.mediaUpdateInterval;
        Config.dashboard.performance.showBattery = root.showBattery;
        Config.dashboard.performance.showGpu = root.showGpu;
        Config.dashboard.performance.showCpu = root.showCpu;
        Config.dashboard.performance.showMemory = root.showMemory;
        Config.dashboard.performance.showStorage = root.showStorage;
        // Note: sizes properties are readonly and cannot be modified
        Config.save();
    }

    ClippingRectangle {
        id: dashboardClippingRect
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        anchors.leftMargin: 0
        anchors.rightMargin: Appearance.padding.normal

        radius: dashboardBorder.innerRadius
        color: "transparent"

        Loader {
            id: dashboardLoader

            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large

            asynchronous: true
            sourceComponent: dashboardContentComponent
        }
    }

    InnerBorder {
        id: dashboardBorder
        leftThickness: 0
        rightThickness: Appearance.padding.normal
    }

    Component {
        id: dashboardContentComponent

        StyledFlickable {
            id: dashboardFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: dashboardLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: dashboardFlickable
            }

            ColumnLayout {
                id: dashboardLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: Appearance.spacing.normal

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Dashboard")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }
                }

                // General Settings Section
                GeneralSection {
                    rootItem: root
                }

                // Performance Resources Section
                PerformanceSection {
                    rootItem: root
                }

                // Two-column layout for Media and Widget Sizes
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal
                    Layout.alignment: Qt.AlignTop

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Appearance.spacing.normal

                        // Media Widget Section
                        MediaSection {
                            rootItem: root
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Appearance.spacing.normal

                        // Widget Sizes Section
                        WidgetSizesSection {
                            rootItem: root
                        }
                    }
                }
            }
        }
    }
}
