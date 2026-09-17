import Quickshell.Io

JsonObject {
    property bool expire: true
    property int defaultExpireTimeout: 5000
    property real clearThreshold: 0.3
    property int expandThreshold: 20
    property bool actionOnClick: false
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property int width: 400
        property int image: 41
        property int badge: 20
    }
}
