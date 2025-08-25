import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int hideDelay: 2000
    property Sizes sizes: Sizes {}
    property Sliders sliders: Sliders {}

    component Sizes: JsonObject {
        property int sliderWidth: 30
        property int sliderHeight: 150
    }
    component Sliders: JsonObject {
        property bool showBrightnessSlider: true
    }
}
