import Quickshell.Io

JsonObject {
    property int maxNotifs: 5
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property int border: 100
        property int clockWidth: 800
        property int clockHeight: 200
        property int inputWidth: 600
        property int inputHeight: 200
        property int faceSize: 100
        property int weatherWidth: 400
        property int weatherHeight: 100
        property int mediaWidth: 600
        property int mediaWidthSmall: 450
        property int mediaHeight: 170
        property int mediaHeightSmall: 150
        property int mediaCoverSize: 150
        property int mediaCoverSizeSmall: 120
        property int mediaCoverBorder: 3
        property int largeScreenWidth: 2560
        property int smallScreenWidth: 1080
        property int buttonsWidth: 400
        property int buttonsWidthSmall: 300
    }
}
