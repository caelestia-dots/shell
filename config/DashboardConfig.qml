import Quickshell.Io

JsonObject {
    property int mediaUpdateInterval: 500
    property int visualiserBars: 45
    property Sizes sizes: Sizes {}

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
