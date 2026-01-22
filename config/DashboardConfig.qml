import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: true
    property int mediaUpdateInterval: 500
    property int dragThreshold: 50
    property Sizes sizes

    sizes: Sizes {
    }

    property Performance performance

    performance: Performance {
    }

    component Performance: JsonObject {
        property bool showBattery: false
        property bool showGpu: true
        property bool showCpu: true
        property bool showMemory: true
        property bool showStorage: false
        property bool showNetwork: true
        property int updateInterval: 3000
        property int usageTextSize: 12
        property int valueLabelSize: 10
        property int percentageTextSize: 24
        property int normalTextSize: 14
        property int largeIconSize: 20
        property int tempBarHeight: 6
        property real tempBarWidthMult: 0.5
        property int gaugeLineWidth: 10
        property int gaugeRadiusOffset: 12
        property int heroCardTopMargin: 8
        property int heroCardBottomMargin: 8
        property int heroCardLeftMargin: 16
        property int heroCardRightMargin: 16
        property int heroCardRightValueMargin: 32
        property int batteryTankMargin: 16
        property int mainValueSpacing: 0
        property int percentValueSpacing: -4
        property int gaugeCardMargin: 16
    }

    component Sizes: JsonObject {
        readonly property int tabIndicatorHeight: 3
        readonly property int tabIndicatorSpacing: 5
        readonly property int infoWidth: 200
        readonly property int infoIconSize: 25
        readonly property int dateTimeWidth: 110
        readonly property int mediaWidth: 200
        readonly property int mediaProgressSweep: 180
        readonly property int mediaProgressThickness: 8
        readonly property int resourceProgessThickness: 10
        readonly property int weatherWidth: 250
        readonly property int mediaCoverArtSize: 150
        readonly property int mediaVisualiserSize: 80
        readonly property int resourceSize: 200
    }

}
