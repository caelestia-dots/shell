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
    
    // Performance Styling
    property int usageTextSize: Config.dashboard.performance.usageTextSize ?? 12
    property int valueLabelSize: Config.dashboard.performance.valueLabelSize ?? 10
    property int percentageTextSize: Config.dashboard.performance.percentageTextSize ?? 24
    property int normalTextSize: Config.dashboard.performance.normalTextSize ?? 14
    property int largeIconSize: Config.dashboard.performance.largeIconSize ?? 20
    property int tempBarHeight: Config.dashboard.performance.tempBarHeight ?? 6
    property real tempBarWidthMult: Config.dashboard.performance.tempBarWidthMult ?? 0.5
    property int gaugeLineWidth: Config.dashboard.performance.gaugeLineWidth ?? 10
    property int gaugeRadiusOffset: Config.dashboard.performance.gaugeRadiusOffset ?? 12
    property int diskIndicatorWidth: Config.dashboard.performance.diskIndicatorWidth ?? 4
    property int diskIndicatorRadius: Config.dashboard.performance.diskIndicatorRadius ?? 2
    property int heroCardTopMargin: Config.dashboard.performance.heroCardTopMargin ?? 8
    property int heroCardBottomMargin: Config.dashboard.performance.heroCardBottomMargin ?? 8
    property int heroCardLeftMargin: Config.dashboard.performance.heroCardLeftMargin ?? 16
    property int heroCardRightMargin: Config.dashboard.performance.heroCardRightMargin ?? 16
    property int heroCardRightValueMargin: Config.dashboard.performance.heroCardRightValueMargin ?? 32
    property int batteryTankMargin: Config.dashboard.performance.batteryTankMargin ?? 16
    property int mainValueSpacing: Config.dashboard.performance.mainValueSpacing ?? -8
    property int percentValueSpacing: Config.dashboard.performance.percentValueSpacing ?? -4
    property int gaugeCardMargin: Config.dashboard.performance.gaugeCardMargin ?? 16
    property int storageCardMargin: Config.dashboard.performance.storageCardMargin ?? 16
    property int diskRowTopMargin: Config.dashboard.performance.diskRowTopMargin ?? 2
    property int diskRowBottomMargin: Config.dashboard.performance.diskRowBottomMargin ?? 2
    property int diskRowProgressTopMargin: Config.dashboard.performance.diskRowProgressTopMargin ?? 4
    property int diskRowProgressBottomMargin: Config.dashboard.performance.diskRowProgressBottomMargin ?? 4

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
        Config.dashboard.performance.usageTextSize = root.usageTextSize;
        Config.dashboard.performance.valueLabelSize = root.valueLabelSize;
        Config.dashboard.performance.percentageTextSize = root.percentageTextSize;
        Config.dashboard.performance.normalTextSize = root.normalTextSize;
        Config.dashboard.performance.largeIconSize = root.largeIconSize;
        Config.dashboard.performance.tempBarHeight = root.tempBarHeight;
        Config.dashboard.performance.tempBarWidthMult = root.tempBarWidthMult;
        Config.dashboard.performance.gaugeLineWidth = root.gaugeLineWidth;
        Config.dashboard.performance.gaugeRadiusOffset = root.gaugeRadiusOffset;
        Config.dashboard.performance.diskIndicatorWidth = root.diskIndicatorWidth;
        Config.dashboard.performance.diskIndicatorRadius = root.diskIndicatorRadius;
        Config.dashboard.performance.heroCardTopMargin = root.heroCardTopMargin;
        Config.dashboard.performance.heroCardBottomMargin = root.heroCardBottomMargin;
        Config.dashboard.performance.heroCardLeftMargin = root.heroCardLeftMargin;
        Config.dashboard.performance.heroCardRightMargin = root.heroCardRightMargin;
        Config.dashboard.performance.heroCardRightValueMargin = root.heroCardRightValueMargin;
        Config.dashboard.performance.batteryTankMargin = root.batteryTankMargin;
        Config.dashboard.performance.mainValueSpacing = root.mainValueSpacing;
        Config.dashboard.performance.percentValueSpacing = root.percentValueSpacing;
        Config.dashboard.performance.gaugeCardMargin = root.gaugeCardMargin;
        Config.dashboard.performance.storageCardMargin = root.storageCardMargin;
        Config.dashboard.performance.diskRowTopMargin = root.diskRowTopMargin;
        Config.dashboard.performance.diskRowBottomMargin = root.diskRowBottomMargin;
        Config.dashboard.performance.diskRowProgressTopMargin = root.diskRowProgressTopMargin;
        Config.dashboard.performance.diskRowProgressBottomMargin = root.diskRowProgressBottomMargin;
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
